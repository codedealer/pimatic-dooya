module.exports = (env) ->
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  t = env.require('decl-api').types
  M = env.matcher
  rpio = require 'rpio'

  class Dooya extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins`
    #     section of the config.json file
    #
    #
    init: (app, @framework, @config) =>
      deviceConf = require './device-config-schema'

      @framework.deviceManager.registerDeviceClass('DooyaRemote', {
        configDef: deviceConf.DooyaRemote,
        createCallback: (config) => new DooyaRemoteDevice(config, @, deviceConf.DooyaRemote)
      })

  class DooyaRemoteDevice extends env.devices.Device
    actions:
      moveUp:
        description: 'Roll curtains up'
      moveDown:
        description: 'Roll curtains down'
      stop:
        description: 'Stop curtains'

    moveUp: () ->
      return new Promise (resolve, reject) =>
        send(@cmd.wakeup, 3)
        rpio.msleep(15)
        send(@cmd.up, 3)
        resolve()

    moveDown: () ->
      return new Promise (resolve, reject) =>
        send(@cmd.wakedown, 3)
        rpio.msleep(15)
        send(@cmd.down, 3)
        resolve()

    stop: () ->
      return new Promise (resolve, reject) =>
        send(@cmd.stop, 3)
        resolve()

    constructor: (@config, @plugin, @deviceConf) ->
      @id = @config.id
      @name = @config.name
      @remoteId = @deviceConf.remoteId
      @pin = @plugin.config.pin
      # keep the state of the pin so that devices
      # do not hog the GPIO unnecesseraly
      @opened = false
      # codes for supported commands
      @cmd = {
        wakeup: 17,
        up: 30,
        wakedown: 51,
        down: 60,
        stop: 85
      }
      # latency for different pulses
      @lut = {
        HSTART: 4830,
        LSTART: 1535,
        LSHORT: 415,
        HSHORT: 340,
        LLONG: 750,
        HLONG: 685
      }

      rpio.open(@pin)
      rpio.usleep(10) #first call has lag
      @opened = true

      super()

    destroy: () ->
      rpio.close(@pin)
      @opened = false
      super()

    _pulse: (bit) ->
      level = if @remoteId & (1 << bit) then 1 else 0
      if level
        rpio.write(@pin, 1)
        rpio.usleep(@lut.HLONG)
        rpio.write(@pin, 0)
        rpio.usleep(@lut.LSHORT)
      else
        rpio.write(@pin, 1)
        rpio.usleep(@lut.HSHORT)
        rpio.write(@pin, 0)
        rpio.usleep(@lut.LLONG)

    send: (cmd, repeat) ->
      if not @opened
        rpio.open(@pin)
        rpio.usleep(10) #first call has lag

      rpio.write(@pin, 1)
      rpio.usleep(@lut.HSTART)
      rpio.write(@pin, 0)
      rpio.usleep(@lut.LSTART)

      # send remote id
      @_pulse @remoteId, bit for bit in [31..0]

      # send command
      @_pulse cmd, bit for bit in [7..0]

      repeat--

      @send(cmd, repeat) if repeat

  # ###Finally
  # Create a instance of my plugin
  dooya = new Dooya
  # and return it to the framework.
  return dooya
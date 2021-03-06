# file: index.coffee

EventEmitter = require('events').EventEmitter

class Plugin extends EventEmitter

  constructor: (@app, @opts)->
    @name = 'mongodb'
    @collections = {}
    @client = @opts?.client or require('mongodb').MongoClient
    @db = null
    @connect (err)=>
      @registerEvents()
      @db.collectionNames (err, names)=>
        names = (names.map (x)-> x.name.split('.')[1]).filter (name)-> name.split('.')[0] != "system"
        @loadCollection name for name in names

  connect: (done)->
    return done new Error 'No MongoDB URL set' unless @opts?.url?
    @client.connect @opts.url, (err, @db)=>
      done err

  loadCollection: (resource)->
    @collections[resource] = @db.collection resource
    cursor = @collections[resource].find({}).toArray (err, results)=>
      if results?.length > 0
        @app.db[resource] = results

  registerEvents: ->

    @app.on 'POST', (req, res)=>
      resource = req.resource
      data = res.result[0]
      unless @collections[resource]?
        @collections[resource] = @db.collection resource
      @collections[resource].insert data, (err, docs)->

    @app.on 'DELETE', (req, res)=>
      resource = req.resource
      items = res.result
      if @collections[resource]?
        ids = items.map (x)-> x._id
        selector = {'_id':{$in:ids}}
        @collections[resource].remove selector, (err, count)->

    @app.on 'PATCH', (req, res)=>
      resource = req.resource
      items = res.result
      data = req.body
      if @collections[resource]?
        ids = items.map (x)-> x._id
        opts = multi: true
        selector = { '_id':{ $in:ids } }
        delta = {}
        for k,v of data
          delta["props."+k] = v
        @collections[resource].update selector, { $set: delta }, opts, (err, count)->

    @app.on 'PUT', (req, res)=>
      resource = req.resource
      items = res.result
      data = req.body
      if @collections[resource]?
        ids = items.map (x)-> x._id
        opts = multi: true
        selector = { '_id':{ $in:ids } }
        if data.links?
          @collections[resource].update selector, { $push: { links: { $each: data.links } } }, opts, (err, count)->

module.exports = (app, opts)->
  return new Plugin app, opts

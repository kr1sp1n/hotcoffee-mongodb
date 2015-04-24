# file: test/test_plugin_mongodb.coffee

should = require 'should'
sinon = require 'sinon'
EventEmitter = require('events').EventEmitter


describe 'mongodb Plugin', ->
  before ->
    @turtleNames = ['Donatello', 'Leonardo', 'Michelangelo', 'Raphael']

  beforeEach ->
    @turtles = for name, i in @turtleNames
      { _id: i+1, props: { name: name, id: i+1 }, links: [] }
    @links = {}
    for name1, i in @turtleNames
      @links[name1] = []
      for name2, j in @turtleNames
        if name1 != name2
          @links[name1].push { rel: 'brother', href: "link to #{name2}", type: 'application/json' }

    @app = new EventEmitter()
    @app.db = {}
    @db =
      collectionNames: sinon.stub()
      collection: sinon.stub()
    @collection =
      find: sinon.stub()
      toArray: sinon.stub()
      insert: sinon.stub()
      update: sinon.stub()
      remove: sinon.stub()

    @collection.toArray.yields null, @turtles
    @collection.find.returns @collection
    @db.collection.returns @collection

    @db.collectionNames.callsArgWith 0, null, [{name:'testdb.turtle'}]
    @client =
      connect: sinon.stub()
    @client.connect.callsArgWith 1, null, @db # stub callback
    @opts =
      url: "fake_mongodb_url"
      client: @client
    @plugin = require("#{__dirname}/../index")(@app, @opts)

  it 'should expose its right name', ->
    @plugin.name.should.equal 'mongodb'


  describe 'connect(done)', ->

    it 'should connect to MongoDB if opts.url is set', (done)->
      @plugin.connect (err)=>
        done err

    it 'should return an error if no MongoDB URL was set', (done)->
      @plugin.opts.url = null
      @plugin.connect (err)=>
        should(err).be.ok
        err.message.should.equal "No MongoDB URL set"
        done null


  describe 'loadCollection(resource)', ->

    it 'should load MongoDB collections in the app DB', ->
      resource = 'turtle'
      @plugin.loadCollection resource
      @db.collection.called.should.be.ok
      @db.collection.calledWith(resource).should.be.ok
      @app.db[resource].should.equal @turtles


  describe 'registerEvents()', ->

    it 'should listen on "POST" events from the app', ->
      resource = 'beatles'
      data = name: 'John Lennon'
      @plugin.registerEvents()
      @app.emit 'POST', resource, data
      @db.collection.calledWith(resource).should.be.ok
      @collection.insert.called.should.be.ok
      @collection.insert.calledWith(data).should.be.ok

    it 'should listen on "PATCH" events from the app', ->
      resource = 'turtle'
      items = @turtles
      data = status: 'hungry'
      @plugin.registerEvents()
      @app.emit 'PATCH', resource, items, data
      @collection.update.called.should.be.ok

    it 'should listen on "DELETE" events from the app', ->
      resource = 'turtle'
      items = @turtles
      @plugin.registerEvents()
      @app.emit 'DELETE', resource, items
      @collection.remove.called.should.be.ok

    it 'should listen on "PUT" events from the app', ->
      resource = 'turtle'
      items = @turtles
      data = links: [ { rel: 'master', href: 'link to Splinter', type: 'application/json' } ]
      @plugin.registerEvents()
      @app.emit 'PUT', resource, items, data
      @collection.update.called.should.be.ok

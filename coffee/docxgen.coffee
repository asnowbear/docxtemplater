###
Docxgen.coffee
Created by Edgar HIPP
###
DocUtils=require('./docUtils')

DocxGen=class DocxGen
	constructor:(content,options) ->
		@moduleManager=new DocxGen.ModuleManager()
		@moduleManager.gen=this
		@templateClass=@getTemplateClass()
		@setOptions({})
		if content? then @load(content,options)
	attachModule:(module)->
		@moduleManager.attachModule(module)
		this
	setOptions:(@options={})->
		for key,defaultValue of DocUtils.defaults
			this[key]=if @options[key]? then @options[key] else defaultValue
		this
	getTemplateClass:->DocxGen.DocXTemplater
	getTemplatedFiles:->
		slideTemplates=@zip.file(/word\/(header|footer)\d+\.xml/).map (file) -> file.name
		slideTemplates.concat ["word/document.xml"]
	load: (content,options)->
		@moduleManager.sendEvent('loading')
		if content.file?
			@zip=content
		else
			@zip = new DocxGen.JSZip content,options
		@moduleManager.sendEvent('loaded')
		@templatedFiles = @getTemplatedFiles()
		this
	renderFile:(fileName)->
		@moduleManager.sendEvent('rendering-file',fileName)
		currentFile= @createTemplateClass(fileName)
		@zip.file(fileName,currentFile.render().content)
		@moduleManager.sendEvent('rendered-file',fileName)
	render:()->
		@moduleManager.sendEvent('rendering')
		#Loop inside all templatedFiles (basically xml files with content). Sometimes they dont't exist (footer.xml for example)
		for fileName in @templatedFiles when @zip.files[fileName]?
			@renderFile(fileName)
		@moduleManager.sendEvent('rendered')
		this
	getTags:()->
		usedTags=[]
		for fileName in @templatedFiles when @zip.files[fileName]?
			currentFile = @createTemplateClass(fileName)
			usedTemplateV= currentFile.render().usedTags
			if DocUtils.sizeOfObject(usedTemplateV)
				usedTags.push {fileName,vars:usedTemplateV}
		usedTags
	setData:(@tags) ->
		this
	#output all files, if docx has been loaded via javascript, it will be available
	getZip:()->
		@zip
	createTemplateClass:(path)->
		usedData=@zip.files[path].asText()
		obj =
			tags:@tags
			moduleManager:@moduleManager
		for key,_ of DocUtils.defaults
			obj[key]=this[key]
		new @templateClass(usedData,obj)
	getFullText:(path="word/document.xml") ->
		@createTemplateClass(path).getFullText()

DocxGen.DocUtils=require('./docUtils')
DocxGen.DocXTemplater=require('./docxTemplater')
DocxGen.JSZip=require('jszip')
DocxGen.ModuleManager=require('./moduleManager')
DocxGen.XmlTemplater=require('./xmlTemplater')
DocxGen.XmlMatcher=require('./xmlMatcher')
DocxGen.XmlUtil=require('./xmlUtil')
DocxGen.SubContent=require('./subContent')
module.exports=DocxGen

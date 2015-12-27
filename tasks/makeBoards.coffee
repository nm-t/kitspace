yaml        = require('js-yaml')
fs          = require('fs')
path        = require('path')
globule     = require('globule')
{checkArgs} = require('./utils/utils')
cp          = require('child_process')

boardDir = 'boards'

if require.main != module

    exports.deps = [boardDir]
    exports.targets = ['build/boards.json']

else
    getGithubInfo = (id) ->
        text = cp.execSync("curl https://api.github.com/repos/#{id}")
        return JSON.parse(text)

    getGithubReadmePath = (folder) ->
        files = globule.find("#{folder}/*", {filter:'isFile'})
        readmes = files.filter (f) ->
            /README.(markdown|mdown|mkdn|md|textile|rdoc|org|creole|mediawiki|wiki|rst|asciidoc|adoc|asc|pdo)/i.test(f)
        return readmes[0]


    correctTypes = (boardInfo) ->
        boardInfoWithEmpty =
            { name        : ''
            , description : ''
            , site        : ''
            , license     : ''
            }
        for prop of boardInfoWithEmpty
            if (boardInfo.hasOwnProperty(prop))
                boardInfoWithEmpty[prop] = String(boardInfo[prop])
        return boardInfoWithEmpty


    {deps, targets} = checkArgs(process.argv)
    boards = []
    folders = globule.find("#{boardDir}/*/*", {filter: 'isDirectory'})
    folders.sort((a,b) ->
        return (a.toLowerCase() > b.toLowerCase())
    )

    for folder in folders
        file = undefined
        try
            file = fs.readFileSync("#{folder}/kitnic.yaml")
        if file?
            info = yaml.safeLoad(file)
        else
            info = {}
        info = correctTypes(info)
        info.id = path.relative(boardDir, folder)
        if info.description == '' || info.site == ''
            ghInfo = getGithubInfo(info.id)
            if info.description == ''
                info.description = ghInfo.description
            if info.site == '' and ghInfo.homepage?
                info.site = ghInfo.homepage
            if info.site == ''
                info.site = "https://github.com/#{info.id}"
        readme_path = getGithubReadmePath(folder)
        if readme_path?
            info.readme = fs.readFileSync(readme_path, {encoding:'utf8'})
        else
            info.readme = ''
        boards.push(info)

    boardJson = fs.openSync(targets[0], 'w')
    fs.write(boardJson, JSON.stringify(boards))

import fs from "fs"
import options from "commander"
import glob from "glob"
import {fileURLToPath} from "url"

if (process.argv[1] === fileURLToPath(import.meta.url)) {
	options
		.usage('make|dist')
		.arguments('<target>')
		.parse(process.args)

	prepareMobileBuild(options.args[0])
}

/**
 * Removes source maps, icons, HTML files which are not needed for mobile apps.
 */
export function prepareMobileBuild(buildType) {
	console.log("prepare mobile build for build type", buildType)
	let prefix
	switch (buildType) {
		case "dist":
			prefix = "build/dist/"
			break
		case "make":
			prefix = "build/"
			break
		default:
			throw new Error("Unknown build type " + buildType)
	}

	const imagesPath = prefix + "images"
	const imagesToKeep = [
		"ionicons.ttf", "logo-solo-red.png"
	]
	if (fs.existsSync(imagesPath)) {
		const imageFiles = glob.sync(prefix + "images/*")
		for (let file of imageFiles) {
			const doDiscard = !imagesToKeep.find(name => file.endsWith(name))
			if (doDiscard) {
				console.log("unlinking ", file)
				fs.unlinkSync(file)
			}
		}
	} else {
		console.log("No folder at", imagesPath)
	}

	const maps = glob.sync(prefix + "*.js.map")
	for (let file of maps) {
		console.log("unlinking ", file)
		fs.unlinkSync(file)
	}
	const indexHtmlPath = prefix + "index.html"
	if (fs.existsSync(indexHtmlPath)) {
		fs.unlinkSync(indexHtmlPath)
		console.log("rm ", indexHtmlPath)
	} else {
		console.log("no file at", indexHtmlPath)
	}
}

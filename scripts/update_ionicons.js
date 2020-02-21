const fs = require('fs')
const proc = require('child_process')
const format = require('format')
const webfontsGenerator = require('webfonts-generator2')

const fontFile = '../res/Ionicons.ttf'
const dartFile = '../lib/ionicons.g.dart'
const dartHeader = `import 'package:flutter/widgets.dart';

class Ionicons {
  Ionicons._();

  static const String iconFont = 'Ionicons';
`
const dartConstant = `
  static const IconData %s = IconData(0x%s, fontFamily: iconFont, matchTextDirection: true);
`
const dartFooter = '}\n'

const iconFontGenerator = './node_modules/.bin/svgicons2svgfont'
const iconsSrc = './node_modules/ionicons/dist/svg'
const buildDir = './build'

if (!fs.existsSync(buildDir)) {
  fs.mkdirSync(buildDir)
}
webfontsGenerator({
  files: fs.readdirSync(iconsSrc).map((e) => `${iconsSrc}/${e}`).filter((e) => e.endsWith('.svg')),
  fontName: 'Ionicons',
  dest: buildDir,
  types: ['ttf']
}, (error) => {
  if (error) {
    console.log('Unexpected exception:', error)
  } else {
    const css = fs.readFileSync(`${buildDir}/Ionicons.css`).toString()
    const keys = css.match(/\.icon-([a-z\-]+)/g)
    const values = css.match(/"\\[a-z0-9]+"/g)
    const codepoints = {}
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i].replace(/\.icon-/, '').replace(/-/g, '_')
      const value = values[i].replace(/["\\]+/g, '')
      codepoints[key] = value
    }

    fs.copyFileSync(`${buildDir}/Ionicons.ttf`, fontFile)

    fs.writeFileSync(dartFile, dartHeader)
    for (let key in codepoints) {
      fs.appendFileSync(dartFile, format(dartConstant, key, codepoints[key]))
    }
    fs.appendFileSync(dartFile, dartFooter)
  }
})

const fs = require('fs')
const format = require('format')

const fontFile = '../res/Ionicons.ttf'
const dartFile = '../lib/ionicons.g.dart'
const dartHeader = `import 'package:flutter/widgets.dart';

class Ionicons {
  Ionicons._();

  // Generated code: do not hand-edit.
  // See https://github.com/KagurazakaHanabi/dailypics/blob/master/scripts/README.md
  // BEGIN GENERATED`

const dartConstant = `

  static const IconData %s = IconData(0x%s, fontFamily: 'Ionicons');`

const dartFooter = `
  // END GENERATED
}
`

const mainfest = JSON.parse(fs.readFileSync('.fontcustom-manifest.json').toString())

fs.writeFileSync(dartFile, dartHeader)
for(let key in mainfest.glyphs) {
  let value = parseInt(mainfest.glyphs[key].codepoint).toString(16)
  fs.appendFileSync(dartFile, format(dartConstant, key.replace(/-/g, '_'), value))
}
fs.appendFileSync(dartFile, dartFooter)

_ = require 'underscore'
gulp = require 'gulp'
jade = require 'gulp-jade'
stylus = require 'gulp-stylus'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
imagemin = require 'gulp-imagemin'
browserify = require 'gulp-browserify'
browserSync = require 'browser-sync'
spritesmith = require 'gulp.spritesmith'
plumber = require 'gulp-plumber'
pngcrush = require 'imagemin-pngcrush'
pngquant = require 'imagemin-pngquant'

expand = (ext)-> rename (path) -> _.tap path, (p) -> p.extname = ".#{ext}"

DEST = "./htdocs"
SRC = "./src"

# ファイルタイプごとに無視するファイルなどを設定
paths =
  js: ["#{SRC}/**/*.coffee", "!#{SRC}/**/_**/*.coffee", "!#{SRC}/**/_*.coffee"]
  html: ["#{SRC}/**/*.jade", "!#{SRC}/**/_**/*.jade", "!#{SRC}/**/_*.jade"]
  css: ["#{SRC}/**/*.styl", "!#{SRC}/**/sprite*.styl", "!#{SRC}/**/_**/*.styl", "!#{SRC}/**/_*.styl"]
  img: ["#{SRC}/**/*.{png, jpg, gif}", "!#{SRC}/**/sprite/**/*.png"]
  reload: ["#{DEST}/**/*", "!#{DEST}/**/*.css"]
  sprite: "#{SRC}/**/sprite/**/*.png"

gulp.task 'browserify', ->
  gulp.src paths.js, read: false
    .pipe plumber()
    .pipe browserify
        debug: false
        transform: ['coffeeify', 'stylify', 'debowerify']
        extensions: ['.coffee'],
    .pipe expand "js"
    #.pipe uglify()
    .pipe gulp.dest DEST

# FW for Stylus
nib = require 'nib'

#added Aug1/2014
gulp.task "jade" ->
  gulp.src paths.html
    .pipe jade()
    .pipe gulp.dest DEST

gulp.task "stylus", ["sprite"], ->
  gulp.src paths.css
    .pipe plumber()
    .pipe stylus use: nib(), errors: true
    .pipe expand "css"
    .pipe gulp.dest DEST
    .pipe browserSync.reload stream:true

gulp.task "imagemin", ->
  gulp.src paths.img
    .pipe imagemin
      use: [pngcrush(), pngquant()]
    .pipe gulp.dest DEST

gulp.task "browser-sync", ->
  browserSync.init null,
    reloadDelay:2000,
    #startPath: 'a.html'
    server: baseDir: DEST

# http://blog.e-riverstyle.com/2014/02/gulpspritesmithcss-spritegulp.html
gulp.task "sprite", ->
  a = gulp.src paths.sprite
    .pipe plumber()
    .pipe spritesmith
      imgName: 'common/img/sprite.png'
      cssName: 'common/css/_mixin/sprite.styl'
      imgPath: '/common/img/sprite.png'
      algorithm: 'binary-tree'
      cssFormat: 'stylus'
      padding: 4

  a.img.pipe gulp.dest SRC
  a.img.pipe gulp.dest DEST
  a.css.pipe gulp.dest SRC

gulp.task 'watch', ->
    gulp.watch [paths.js[0], "#{SRC}/**/_*/*"], ['browserify']
    gulp.watch paths.css  , ['stylus']
    gulp.watch paths.reload, -> browserSync.reload once: true

gulp.task "default", ['stylus', 'browserify', 'browser-sync', 'watch']
gulp.task "build", ['imagemin', 'stylus', 'browserify']

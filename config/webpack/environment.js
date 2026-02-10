const crypto = require('crypto')

// Workaround for legacy dependencies (compression-webpack-plugin 4.x)
// that still use MD4 via OpenSSL, which was removed in Node.js 17+.
// Webpack 4.47.0 and babel-loader 8.2.4+ handle this internally,
// but some plugins still call crypto.createHash('md4') directly.
const originalCreateHash = crypto.createHash
crypto.createHash = (algorithm, options) => {
  return originalCreateHash(algorithm === 'md4' ? 'sha256' : algorithm, options)
}

const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)
module.exports = environment

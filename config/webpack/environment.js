const crypto = require('crypto')
const webpack = require('webpack')

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

// Fix non-deterministic CSS contenthash in mini-css-extract-plugin@0.8.2
// on webpack 4. Two independent causes:
//
// 1) The contentHash hook iterates chunk.modulesIterable (a SortableSet)
//    without calling sort(), so module order varies between builds.
//    Fix: replace the hook with one that sorts modules by identifier.
//
// 2) CssModule.updateHash() includes JSON.stringify(sourceMap), which
//    can vary between machines/builds (absolute paths, property order).
//    Fix: disable source maps in CSS loaders for production/staging.
//
// Ref: https://github.com/webpack-contrib/mini-css-extract-plugin/issues/512
if (process.env.NODE_ENV !== 'development' && process.env.NODE_ENV !== 'test') {
  const MODULE_TYPE = 'css/mini-extract'
  const { util: { createHash: createWebpackHash } } = webpack

  // (1) Disable CSS source maps in all CSS-related loaders so that
  // CssModule.updateHash() hashes only content, not source maps.
  environment.loaders.keys().forEach((key) => {
    const loader = environment.loaders.get(key)
    if (!loader || !loader.use) return

    loader.use.forEach((entry) => {
      if (!entry || !entry.loader) return
      const name = entry.loader
      if (/css-loader|postcss-loader|sass-loader/.test(name)) {
        entry.options = entry.options || {}
        entry.options.sourceMap = false
      }
    })
  })

  // (2) Override the contentHash hook to sort CSS modules by identifier
  // before hashing, ensuring deterministic iteration order.
  environment.plugins.append(
    'DeterministicCssHash',
    {
      apply(compiler) {
        compiler.hooks.compilation.tap('DeterministicCssHash', (compilation) => {
          // Intercept after mini-css-extract-plugin's own tap.
          // Using the same hook name replaces the hash value it computed.
          compilation.hooks.contentHash.tap('DeterministicCssHash', (chunk) => {
            const { outputOptions } = compilation
            const { hashFunction, hashDigest, hashDigestLength } = outputOptions
            const hash = createWebpackHash(hashFunction)

            const modules = Array.from(chunk.modulesIterable)
              .filter((m) => m.type === MODULE_TYPE)
              .sort((a, b) => a.identifier().localeCompare(b.identifier()))

            for (const m of modules) {
              m.updateHash(hash)
            }

            chunk.contentHash[MODULE_TYPE] = hash
              .digest(hashDigest)
              .substring(0, hashDigestLength)
          })
        })
      }
    }
  )
}

module.exports = environment

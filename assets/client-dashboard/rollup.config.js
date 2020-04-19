/* eslint-disable no-undef */
import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import buble from '@rollup/plugin-buble'
import path from 'path'

export default [
  {
    input: 'src/main.js',
    output: {
      name: 'jwp',
      file: path.resolve(__dirname, '../../priv/static/js/console.js'),
      format: 'umd',
    },
    plugins: [resolve(), commonjs(), buble()],
  },
]

const {merge} = require('webpack-merge');

const CopyWebpackPlugin = require("copy-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");

const common = require('./webpack.common.js');

const prod = {
    mode: 'production',
    optimization: {
        minimize: true,
        minimizer: [
            new TerserPlugin()
        ]
    },
    plugins: [
        // Copy static assets
        new CopyWebpackPlugin({
            patterns: [{from: "./assets"}]
        })
    ],
    module: {
        rules: [
            {
                test: /\.elm$/,
                use: {
                    loader: "elm-webpack-loader",
                    options: {
                        optimize: false
                    }
                }
            }
        ]
    }
};

module.exports = merge(common(false), prod);

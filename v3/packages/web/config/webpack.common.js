const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const {CleanWebpackPlugin} = require('clean-webpack-plugin');
const webpack = require('webpack');

module.exports = (withDebug) => {
    return {
        entry: {
            index: path.resolve(__dirname, "../src/js/index.js")
        },
        resolve: {
            fallback: {
                process: require.resolve("process/browser")
            }
        },
        output: {
            path: path.resolve(__dirname, '../dist'),
            filename: 'bundle.js'
        },

        plugins: [
            new HtmlWebpackPlugin({
                template: path.resolve(__dirname, "../src/index.html")
            }),
            new CleanWebpackPlugin(),
            new webpack.EnvironmentPlugin(['CHAT_API_URL'])
        ],
        optimization: {
            // Prevents compilation errors causing the hot loader to lose state
            emitOnErrors: false
        },
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    use: [
                        {loader: "elm-reloader"},
                        {
                            loader: "elm-webpack-loader",
                            options: {
                                // add Elm's debug overlay to output
                                debug: withDebug,
                                optimize: false
                            }
                        }
                    ]
                },
                {
                    test: /\.js$/,
                    exclude: /node_modules/,
                    use: {
                        loader: "babel-loader"
                    }
                },
                {
                    test: /\.(png|svg|jpg|jpeg|gif)$/i,
                    type: 'asset/resource',
                },
            ],
        }
    };
};


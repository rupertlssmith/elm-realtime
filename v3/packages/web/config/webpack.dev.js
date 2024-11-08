const path = require('path');
const {merge} = require('webpack-merge');
const common = require('./webpack.common.js');


const dev = {
    mode: 'development',
    devServer: {
        hot: "only",
        client: {
            logging: "info"
        },
        static: {directory: path.join(__dirname, "../assets")},
        devMiddleware: {
            publicPath: "/",
            stats: "errors-only"
        },
        historyApiFallback: true
    },
};

module.exports = env => {
    const withDebug = false;
    return merge(common(withDebug), dev);
}

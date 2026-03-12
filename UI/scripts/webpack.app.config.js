const path = require("path");
const merge = require("webpack-merge");
const base = require("./webpack.base.config");

module.exports = (env, argv) => {
    // webpack-cli v3 passes --app=crwrite as argv.app;
    // older versions passed it inside env
    const envStr = (typeof env === "object" ? env.env || "production" : env) || "production";
    const appName = (argv && argv.app) || (typeof env === "object" && env.app) || "crwrite";

    return merge(base(envStr, appName), {
        entry: {
            index: "./src/index.js",
            app: "./src/Renderer/renderApp.js"
        },
        output: {
            filename: "[name].js",
            path: path.resolve(__dirname, "../app")
        }
    });
};
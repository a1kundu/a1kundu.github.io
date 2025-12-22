/** @type {import('tailwindcss').Config} */
const plugin = require("tailwindcss/plugin");
const defaultTheme = require("tailwindcss/defaultTheme");
module.exports = {
    content: ["./src/**/*.{html,ts}"],
    theme: {
        extend: {
            fontSize: {
                xxs: ["0.55rem", "0.75rem"],
            },
            fontFamily:{
                myTheme: ['"Noto Sans Display"',defaultTheme],
            }
        },
    },
    plugins: [
        plugin(function ({ addBase }) {
            addBase({
                html: { fontSize: "16px" },
            });
        }),
    ],
};

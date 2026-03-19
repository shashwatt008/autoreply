require("dotenv").config();

const express = require("express");
const axios = require("axios");

const app = express();

const APP_ID = process.env.APP_ID;
const APP_SECRET = process.env.APP_SECRET;

const REDIRECT_URI = "http://localhost:3000/auth/facebook/callback";

// STEP 0: Home route
app.get("/", (req, res) => {
    res.send('<a href="/auth/facebook">Log in with Facebook</a>');
});

// STEP 1: Redirect user to Facebook login
app.get("/auth/facebook", (req, res) => {
    console.log("Redirecting to Facebook Login...");
    const url = `https://www.facebook.com/v18.0/dialog/oauth?client_id=${APP_ID}&redirect_uri=${REDIRECT_URI}&scope=pages_show_list,pages_manage_metadata,pages_messaging`;
    res.redirect(url);
});

// STEP 2: Facebook callback
app.get("/auth/facebook/callback", async (req, res) => {

    const code = req.query.code;

    console.log("Code received:", code);

    if (!code) {

        return res.send("No code received");

    }

    try {

        const tokenRes = await axios.get(
            "https://graph.facebook.com/v18.0/oauth/access_token",
            {
                params: {

                    client_id: APP_ID,
                    client_secret: APP_SECRET,
                    redirect_uri: REDIRECT_URI,
                    code

                }
            }
        );

        console.log("Token response:", tokenRes.data);

        const userAccessToken =
            tokenRes.data.access_token;


        // get pages

        const pagesRes = await axios.get(
            "https://graph.facebook.com/v18.0/me/accounts",
            {
                params: {
                    access_token: userAccessToken
                }
            }
        );

        console.log("Pages:", pagesRes.data);

        res.json(pagesRes.data);

    }

    catch (err) {

        console.log(
            "FULL ERROR:",
            err.response?.data || err.message
        );

        res.send(
            err.response?.data || err.message
        );

    }

});

app.listen(3000, () => console.log("Server running on port 3000"));

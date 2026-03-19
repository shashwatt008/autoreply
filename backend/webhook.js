require("dotenv").config();

const express = require("express");
const bodyParser = require("body-parser");
const axios = require("axios");

const app = express();
app.use(bodyParser.json());

const PAGE_ACCESS_TOKEN = process.env.PAGE_ACCESS_TOKEN;
const VERIFY_TOKEN = process.env.VERIFY_TOKEN;


// 🔥 Your reply rules
const replyRules = {

    "1068878966300425_1111111111111111": "🔥 Thanks for commenting on Post 1",

    "1068878966300425_2222222222222222": "🚀 Thanks for commenting on Post 2",

    "default": "❤️ Thanks for your comment!"

};



// Verification
app.get("/webhook", (req, res) => {

    if (
        req.query["hub.mode"] === "subscribe" &&
        req.query["hub.verify_token"] === VERIFY_TOKEN
    ) {
        res.send(req.query["hub.challenge"]);
    } else {
        res.sendStatus(403);
    }

});



// Event receiver
app.post("/webhook", async (req, res) => {

    const entry = req.body.entry;

    if (entry) {

        const change = entry[0].changes[0].value;

        const commentId = change.comment_id;
        const postId = change.post_id;

        console.log("Comment:", commentId);
        console.log("Post:", postId);


        const replyMessage =
            replyRules[postId] || replyRules["default"];


        await replyComment(commentId, replyMessage);

    }

    res.sendStatus(200);

});



async function replyComment(commentId, message) {

    await axios.post(

        `https://graph.facebook.com/v18.0/${commentId}/comments`,
        {
            message: message
        },
        {
            params: {
                access_token: PAGE_ACCESS_TOKEN
            }
        }

    );

    console.log("Replied:", message);

}



app.listen(3000, () =>
    console.log("Running on port 3000")
);
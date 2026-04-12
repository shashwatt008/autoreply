"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { createClient } from "@supabase/supabase-js";
import { ArrowRight, Check } from "lucide-react";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: (i = 0) => ({
    opacity: 1,
    y: 0,
    transition: { duration: 0.6, delay: i * 0.1, ease: [0.25, 0.4, 0, 1] as [number, number, number, number] },
  }),
};

const features = [
  { title: "Auto-reply to every comment", desc: "Fixed or AI-generated — every comment gets a response that sounds exactly like your brand." },
  { title: "AI-crafted replies", desc: "Set a custom prompt. GPT-4o matches your tone and context so every reply feels human." },
  { title: "Keyword triggers", desc: "Only fire when comments contain words like 'price' or 'interested'. Surgical targeting, zero noise." },
  { title: "Private DM automation", desc: "Send a DM to every commenter automatically — deliver lead magnets, links, and offers at scale." },
  { title: "Catch up on old comments", desc: "Missed setting up earlier? Bulk reply all past comments with human-like delays." },
  { title: "Dashboard & analytics", desc: "Track replies sent, active rules, and all connected pages from one clean workspace." },
];

const steps = [
  { num: "01", title: "Connect", desc: "Login with Facebook and connect your Pages and Instagram business accounts." },
  { num: "02", title: "Train", desc: "Pick a post, set keyword triggers, write your reply prompt or message template." },
  { num: "03", title: "Auto-reply", desc: "Go live. AutoReply handles every DM and comment 24/7 while you focus on your business." },
];

export default function Home() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    setStatus("loading");
    const { error } = await supabase
      .from("autoreply_waitlist")
      .insert([{ email }]);
    if (error && error.code !== "23505") {
      setStatus("error");
    } else {
      setStatus("success");
    }
  };

  return (
    <div className="min-h-screen" style={{ fontFamily: "'Inter', sans-serif" }}>
      {/* Nav */}
      <motion.nav
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: [0.25, 0.4, 0, 1] as [number, number, number, number] }}
        className="sticky top-0 z-50 border-b"
        style={{ background: "rgb(243,243,243)", borderColor: "rgba(0,0,0,0.08)" }}
      >
        <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
          <span className="text-sm font-medium tracking-tight">AutoReply.io</span>
          <div className="flex items-center gap-6 text-sm" style={{ color: "#666" }}>
            <a href="#features">Features</a>
            <a href="#how-it-works">How it works</a>
          </div>
        </div>
      </motion.nav>

      {/* Hero */}
      <section className="py-40" style={{ background: "rgb(243,243,243)" }}>
        <div className="max-w-6xl mx-auto px-6">
          <div className="max-w-3xl mx-auto text-center">
            <motion.div variants={fadeUp} initial="hidden" animate="visible" custom={0}>
              <span
                className="inline-block text-xs uppercase tracking-[0.15em] font-medium px-3 py-1 rounded-full mb-8"
                style={{ background: "#fff", border: "1px solid rgba(0,0,0,0.08)", color: "#666" }}
              >
                Private beta
              </span>
            </motion.div>

            <motion.h1
              variants={fadeUp} initial="hidden" animate="visible" custom={1}
              className="mb-6"
              style={{ fontSize: "54px", fontWeight: 400, lineHeight: 1.1, letterSpacing: "-0.03em", color: "#000" }}
            >
              Auto-reply to every DM. Never miss a lead.
            </motion.h1>

            <motion.p
              variants={fadeUp} initial="hidden" animate="visible" custom={2}
              className="text-base mb-10 max-w-xl mx-auto"
              style={{ color: "#666", lineHeight: 1.6 }}
            >
              AI responds to every Facebook and Instagram message in your brand voice. 24/7. While you sleep.
            </motion.p>

            <motion.div
              variants={fadeUp} initial="hidden" animate="visible" custom={3}
              className="flex items-center justify-center gap-4 flex-wrap"
            >
              <a
                href="#waitlist"
                className="px-6 py-3 rounded-full text-sm font-medium transition-opacity hover:opacity-80"
                style={{ background: "#000", color: "#fff" }}
              >
                Join waitlist
              </a>
              <a href="#how-it-works" className="text-sm" style={{ color: "#666" }}>
                See how it works →
              </a>
            </motion.div>
          </div>

          {/* Chat mockup */}
          <motion.div
            variants={fadeUp} initial="hidden" animate="visible" custom={4}
            className="mt-20 rounded-sm overflow-hidden border max-w-2xl mx-auto"
            style={{ borderColor: "rgba(0,0,0,0.08)", background: "#fff" }}
          >
            <div
              className="flex items-center gap-2 px-5 py-3 border-b"
              style={{ borderColor: "rgba(0,0,0,0.08)", background: "#EBEBEB" }}
            >
              <div className="w-2.5 h-2.5 rounded-full" style={{ background: "rgba(0,0,0,0.15)" }} />
              <div className="w-2.5 h-2.5 rounded-full" style={{ background: "rgba(0,0,0,0.15)" }} />
              <div className="w-2.5 h-2.5 rounded-full" style={{ background: "rgba(0,0,0,0.15)" }} />
              <span className="ml-3 text-xs font-medium" style={{ color: "#999", fontFamily: "monospace" }}>
                Inbox — autoreply.io
              </span>
              <span
                className="ml-auto text-xs px-2 py-0.5 rounded-full font-medium"
                style={{ background: "#000", color: "#fff" }}
              >
                Live
              </span>
            </div>
            <div className="p-8 space-y-4">
              <div className="flex gap-3">
                <div className="w-8 h-8 rounded-full flex-shrink-0" style={{ background: "#EBEBEB" }} />
                <div className="rounded-sm px-4 py-3 text-sm max-w-xs" style={{ background: "#F3F3F3", color: "#000", lineHeight: 1.5 }}>
                  Hey! What&apos;s the price for the pro plan? 👀
                </div>
              </div>
              <div className="flex gap-3 flex-row-reverse">
                <div className="w-8 h-8 rounded-full flex-shrink-0 flex items-center justify-center text-xs font-medium" style={{ background: "#000", color: "#fff" }}>
                  AI
                </div>
                <div className="rounded-sm px-4 py-3 text-sm max-w-xs" style={{ background: "#E1E1E1", color: "#000", lineHeight: 1.5 }}>
                  Hi! Pro is $29/mo — includes unlimited rules and AI replies. Want me to send you the full breakdown? 🙌
                </div>
              </div>
              <div className="flex gap-3">
                <div className="w-8 h-8 rounded-full flex-shrink-0" style={{ background: "#EBEBEB" }} />
                <div className="rounded-sm px-4 py-3 text-sm max-w-xs" style={{ background: "#F3F3F3", color: "#000", lineHeight: 1.5 }}>
                  Yes please! That&apos;d be great.
                </div>
              </div>
              <p className="text-xs text-center" style={{ color: "#999" }}>Replied automatically · 0 seconds ago</p>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Trust bar */}
      <section className="py-10 border-y" style={{ background: "#fff", borderColor: "rgba(0,0,0,0.08)" }}>
        <div className="max-w-6xl mx-auto px-6">
          <div className="flex items-center justify-center gap-12 flex-wrap">
            {["Facebook & Instagram", "GPT-4o powered", "Keyword triggers", "Bulk reply mode", "Analytics dashboard"].map((item) => (
              <span key={item} className="text-sm" style={{ color: "#999" }}>
                {item}
              </span>
            ))}
          </div>
        </div>
      </section>

      {/* Problem */}
      <section className="py-32" style={{ background: "#EBEBEB" }}>
        <div className="max-w-6xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, ease: [0.25, 0.4, 0, 1] as [number, number, number, number] }}
            className="max-w-2xl"
          >
            <p className="text-xs uppercase tracking-[0.15em] font-medium mb-6" style={{ color: "#999" }}>
              The problem
            </p>
            <h2 style={{ fontSize: "48px", fontWeight: 400, lineHeight: 1.1, letterSpacing: "-0.02em", color: "#000" }}>
              Every ignored DM is a lost customer.
            </h2>
            <p className="text-base mt-6" style={{ color: "#666", lineHeight: 1.6, maxWidth: "520px" }}>
              Most businesses reply too slow — or not at all. By the time you see the message, the lead is already gone. AutoReply changes that.
            </p>
          </motion.div>
        </div>
      </section>

      {/* How it works */}
      <section id="how-it-works" className="py-32" style={{ background: "#fff" }}>
        <div className="max-w-6xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, ease: [0.25, 0.4, 0, 1] as [number, number, number, number] }}
            className="mb-16"
          >
            <p className="text-xs uppercase tracking-[0.15em] font-medium mb-4" style={{ color: "#999" }}>How it works</p>
            <h2 style={{ fontSize: "48px", fontWeight: 400, lineHeight: 1.1, letterSpacing: "-0.02em", color: "#000" }}>
              Live in three steps.
            </h2>
          </motion.div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-px" style={{ background: "rgba(0,0,0,0.08)" }}>
            {steps.map((step, i) => (
              <motion.div
                key={step.num}
                initial={{ opacity: 0, y: 24 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: i * 0.1, ease: [0.25, 0.4, 0, 1] as [number, number, number, number] }}
                className="p-10"
                style={{ background: "#fff" }}
              >
                <p className="text-xs font-medium mb-6" style={{ color: "#999" }}>{step.num}</p>
                <p className="text-base font-medium mb-3" style={{ color: "#000" }}>{step.title}</p>
                <p className="text-sm" style={{ color: "#666", lineHeight: 1.6 }}>{step.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="py-32" style={{ background: "#EBEBEB" }}>
        <div className="max-w-6xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, ease: [0.25, 0.4, 0, 1] as [number, number, number, number] }}
            className="mb-16"
          >
            <p className="text-xs uppercase tracking-[0.15em] font-medium mb-4" style={{ color: "#999" }}>Features</p>
            <h2 style={{ fontSize: "48px", fontWeight: 400, lineHeight: 1.1, letterSpacing: "-0.02em", color: "#000" }}>
              Everything you need to automate engagement.
            </h2>
          </motion.div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-px" style={{ background: "rgba(0,0,0,0.08)" }}>
            {features.map((f, i) => (
              <motion.div
                key={f.title}
                initial={{ opacity: 0, y: 24 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: i * 0.08, ease: [0.25, 0.4, 0, 1] as [number, number, number, number] }}
                className="p-10"
                style={{ background: "#EBEBEB" }}
              >
                <p className="text-base font-medium mb-3" style={{ color: "#000" }}>{f.title}</p>
                <p className="text-sm" style={{ color: "#666", lineHeight: 1.6 }}>{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Dark section */}
      <section className="py-32" style={{ background: "#000" }}>
        <div className="max-w-6xl mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, ease: [0.25, 0.4, 0, 1] as [number, number, number, number] }}
          >
            <h2 style={{ fontSize: "48px", fontWeight: 400, lineHeight: 1.1, letterSpacing: "-0.02em", color: "#fff" }}>
              Inbox zero. At scale.
            </h2>
            <p className="text-base mt-6" style={{ color: "rgba(255,255,255,0.5)", lineHeight: 1.6 }}>
              Every message answered. Every lead captured. Every hour of the day.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Waitlist CTA */}
      <section id="waitlist" className="py-32" style={{ background: "rgb(243,243,243)" }}>
        <div className="max-w-6xl mx-auto px-6">
          <div className="max-w-xl mx-auto text-center">
            <motion.div
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, ease: [0.25, 0.4, 0, 1] as [number, number, number, number] }}
            >
              <p className="text-xs uppercase tracking-[0.15em] font-medium mb-6" style={{ color: "#999" }}>
                Join waitlist
              </p>
              <h2 className="mb-4" style={{ fontSize: "48px", fontWeight: 400, lineHeight: 1.1, letterSpacing: "-0.02em", color: "#000" }}>
                Never miss a lead again.
              </h2>
              <p className="text-base mb-10" style={{ color: "#666", lineHeight: 1.6 }}>
                Invite-only early access. Be first.
              </p>

              {status === "success" ? (
                <motion.div
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="inline-flex items-center gap-3 px-6 py-3 text-sm"
                  style={{ border: "1px solid rgba(0,0,0,0.08)", borderRadius: "9999px", background: "#fff", color: "#000" }}
                >
                  <Check className="w-4 h-4" />
                  You&apos;re on the list. We&apos;ll reach out soon.
                </motion.div>
              ) : (
                <form onSubmit={handleSubmit} className="flex gap-2 max-w-md mx-auto">
                  <input
                    type="email"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="flex-1 px-4 py-3 text-sm outline-none"
                    style={{
                      background: "#fff",
                      border: "1px solid rgba(0,0,0,0.12)",
                      borderRadius: "9999px",
                      color: "#000",
                    }}
                  />
                  <button
                    type="submit"
                    disabled={status === "loading"}
                    className="flex items-center gap-2 px-5 py-3 text-sm font-medium transition-opacity hover:opacity-80 disabled:opacity-50"
                    style={{ background: "#000", color: "#fff", borderRadius: "9999px" }}
                  >
                    {status === "loading" ? "..." : (
                      <>Join <ArrowRight className="w-4 h-4" /></>
                    )}
                  </button>
                </form>
              )}
              {status === "error" && (
                <p className="text-sm mt-3" style={{ color: "#666" }}>Something went wrong. Try again.</p>
              )}
            </motion.div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-10 border-t" style={{ borderColor: "rgba(0,0,0,0.08)", background: "rgb(243,243,243)" }}>
        <div className="max-w-6xl mx-auto px-6 flex items-center justify-between">
          <span className="text-sm font-medium">AutoReply.io</span>
          <span className="text-sm" style={{ color: "#999" }}>
            &copy; {new Date().getFullYear()}
          </span>
        </div>
      </footer>
    </div>
  );
}

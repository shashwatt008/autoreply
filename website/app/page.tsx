"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { createClient } from "@supabase/supabase-js";
import {
  MessageSquare, Zap, Bot, Target, BarChart2, Clock,
  ArrowRight, Check
} from "lucide-react";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

const ACCENT = "#3B82F6";
const ACCENT_LIGHT = "#93C5FD";

const features = [
  { icon: MessageSquare, title: "Auto Comment Replies", desc: "Automatically reply to every comment with fixed messages or AI-generated responses tailored to your brand voice." },
  { icon: Bot, title: "AI-Powered Replies", desc: "Use GPT-4o to craft contextual, human-like replies. Set a custom prompt and let AI match your tone perfectly." },
  { icon: Target, title: "Keyword Triggers", desc: "Only fire when comments contain specific keywords like \"link\", \"price\", or \"interested\". Zero noise." },
  { icon: MessageSquare, title: "Private Auto DMs", desc: "Send a private message to every commenter — deliver lead magnets, links, or offers automatically." },
  { icon: Clock, title: "Bulk Reply to Past Comments", desc: "Missed setting up automation earlier? Catch up — reply to all existing comments with human-like delays." },
  { icon: BarChart2, title: "Dashboard & Analytics", desc: "Track replies sent, active rules, and manage all your pages and accounts from one clean dashboard." },
];

const steps = [
  { num: "01", title: "Connect Your Accounts", desc: "Login with Facebook and connect your Pages & Instagram business accounts in seconds." },
  { num: "02", title: "Pick a Post & Set Rules", desc: "Choose a post or reel, pick your trigger type (all, keyword, AI) and craft your reply." },
  { num: "03", title: "Go Live & Relax", desc: "AutoReply handles every comment 24/7. Watch your DMs get delivered and engagement skyrocket." },
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
    <div className="min-h-screen text-white relative overflow-hidden" style={{ backgroundColor: "#0A0A0A" }}>
      {/* Grain */}
      <div
        className="fixed inset-0 pointer-events-none z-0"
        style={{
          backgroundImage: "url(\"data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.04'/%3E%3C/svg%3E\")",
          opacity: 0.4,
        }}
      />
      {/* Grid */}
      <div
        className="fixed inset-0 pointer-events-none z-0"
        style={{
          backgroundImage: "radial-gradient(circle, rgba(255,255,255,0.06) 1px, transparent 1px)",
          backgroundSize: "24px 24px",
        }}
      />
      {/* Blue glow */}
      <div
        className="fixed top-0 left-1/2 -translate-x-1/2 w-[800px] h-[400px] pointer-events-none z-0"
        style={{
          background: `radial-gradient(ellipse at center, ${ACCENT} 0%, transparent 70%)`,
          opacity: 0.1,
        }}
      />

      <div className="relative z-10 max-w-6xl mx-auto px-6">
        {/* Nav */}
        <motion.nav
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
          className="flex items-center justify-between py-6"
        >
          <div className="text-lg font-bold tracking-tight" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
            Auto<span style={{ background: `linear-gradient(135deg, ${ACCENT}, ${ACCENT_LIGHT})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Reply</span>
            <span className="text-white/30">.io</span>
          </div>
          <div className="flex items-center gap-6 text-sm text-white/40">
            <a href="#features" className="hover:text-white transition-colors">Features</a>
            <a href="#how-it-works" className="hover:text-white transition-colors">How it works</a>
          </div>
        </motion.nav>

        {/* Hero */}
        <motion.section
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.1 }}
          className="pt-20 pb-16 text-center max-w-3xl mx-auto"
        >
          <div
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-medium mb-8 border"
            style={{ background: `rgba(59,130,246,0.1)`, borderColor: `rgba(59,130,246,0.3)`, color: ACCENT }}
          >
            <Zap className="w-3 h-3" />
            Trusted by 500+ creators & businesses
          </div>

          <h1
            className="text-5xl md:text-6xl font-bold tracking-tight leading-[1.1] mb-6"
            style={{ fontFamily: "'Space Grotesk', sans-serif" }}
          >
            Auto-reply to every DM.{" "}
            <span
              style={{ background: `linear-gradient(135deg, ${ACCENT}, ${ACCENT_LIGHT})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}
            >
              Never miss a lead.
            </span>
          </h1>

          <p className="text-white/50 text-lg leading-relaxed mb-10 max-w-xl mx-auto">
            AutoReply.io automatically responds to Facebook & Instagram comments,
            sends private DMs, and uses AI to craft perfect replies — 24/7, on autopilot.
          </p>

          {/* Platforms */}
          <div className="flex justify-center gap-4 mb-10">
            <div
              className="flex items-center gap-2 px-4 py-2 rounded-xl border text-sm"
              style={{ background: "rgba(255,255,255,0.04)", borderColor: "rgba(255,255,255,0.08)", color: "#93C5FD" }}
            >
              <span className="text-base">📘</span> Facebook
            </div>
            <div
              className="flex items-center gap-2 px-4 py-2 rounded-xl border text-sm"
              style={{ background: "rgba(255,255,255,0.04)", borderColor: "rgba(255,255,255,0.08)", color: "#F9A8D4" }}
            >
              <span className="text-base">📸</span> Instagram
            </div>
          </div>

          {/* Stats */}
          <div className="flex justify-center gap-12 mb-12">
            {[["10M+", "Replies Sent"], ["500+", "Active Users"], ["4.9★", "Rating"]].map(([num, label]) => (
              <div key={label} className="flex flex-col items-center">
                <span className="text-2xl font-bold" style={{ color: ACCENT }}>{num}</span>
                <span className="text-xs text-white/40 mt-1">{label}</span>
              </div>
            ))}
          </div>

          {/* Waitlist */}
          {status === "success" ? (
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="inline-flex items-center gap-3 px-6 py-3 rounded-xl text-sm font-medium"
              style={{ background: `rgba(59,130,246,0.15)`, border: `1px solid rgba(59,130,246,0.4)`, color: ACCENT_LIGHT }}
            >
              <Check className="w-4 h-4" />
              You&apos;re on the waitlist! We&apos;ll reach out soon.
            </motion.div>
          ) : (
            <form onSubmit={handleSubmit} className="flex gap-2 max-w-md mx-auto">
              <input
                type="email"
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="flex-1 px-4 py-3 rounded-xl text-sm text-white placeholder-white/30 outline-none"
                style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.1)" }}
              />
              <button
                type="submit"
                disabled={status === "loading"}
                className="flex items-center gap-2 px-5 py-3 rounded-xl text-sm font-semibold disabled:opacity-50"
                style={{ background: `linear-gradient(135deg, ${ACCENT}, #1D4ED8)`, color: "#fff" }}
              >
                {status === "loading" ? "..." : (<>Get early access <ArrowRight className="w-4 h-4" /></>)}
              </button>
            </form>
          )}
          {status === "error" && <p className="text-red-400 text-xs mt-2">Something went wrong. Try again.</p>}
          <p className="text-white/25 text-xs mt-4">No spam. Launch invite only.</p>
        </motion.section>

        {/* Features */}
        <motion.section
          id="features"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="py-20"
        >
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-14"
          >
            <h2 className="text-3xl md:text-4xl font-bold mb-3" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
              Everything you need to{" "}
              <span style={{ background: `linear-gradient(135deg, ${ACCENT}, ${ACCENT_LIGHT})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
                automate engagement
              </span>
            </h2>
            <p className="text-white/40 text-base">Set up once, let AutoReply handle the rest</p>
          </motion.div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {features.map((f, i) => (
              <motion.div
                key={f.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.08 }}
                className="p-6 rounded-2xl border"
                style={{ background: "rgba(255,255,255,0.03)", borderColor: "rgba(255,255,255,0.07)" }}
              >
                <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-4" style={{ background: `rgba(59,130,246,0.12)` }}>
                  <f.icon className="w-5 h-5" style={{ color: ACCENT }} />
                </div>
                <h3 className="text-base font-semibold mb-2" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>{f.title}</h3>
                <p className="text-sm text-white/45 leading-relaxed">{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </motion.section>

        {/* How it works */}
        <motion.section
          id="how-it-works"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="py-20 border-t"
          style={{ borderColor: "rgba(255,255,255,0.06)" }}
        >
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-14"
          >
            <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
              Set up in{" "}
              <span style={{ background: `linear-gradient(135deg, ${ACCENT}, ${ACCENT_LIGHT})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
                3 minutes
              </span>
            </h2>
          </motion.div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {steps.map((s, i) => (
              <motion.div
                key={s.num}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.12 }}
                className="text-center"
              >
                <div
                  className="inline-flex items-center justify-center w-12 h-12 rounded-2xl text-sm font-bold mb-5"
                  style={{ background: `rgba(59,130,246,0.15)`, color: ACCENT, fontFamily: "'Space Grotesk', sans-serif" }}
                >
                  {s.num}
                </div>
                <h3 className="text-base font-semibold mb-2" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>{s.title}</h3>
                <p className="text-sm text-white/45 leading-relaxed">{s.desc}</p>
              </motion.div>
            ))}
          </div>
        </motion.section>

        {/* CTA */}
        <motion.section
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="py-20 text-center border-t"
          style={{ borderColor: "rgba(255,255,255,0.06)" }}
        >
          <h2 className="text-3xl md:text-4xl font-bold mb-4" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
            Ready to automate your replies?
          </h2>
          <p className="text-white/40 mb-8">Join 500+ creators who save hours every week.</p>
          {status !== "success" && (
            <form onSubmit={handleSubmit} className="flex gap-2 max-w-sm mx-auto">
              <input
                type="email"
                placeholder="your@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="flex-1 px-4 py-3 rounded-xl text-sm text-white placeholder-white/30 outline-none"
                style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.1)" }}
              />
              <button
                type="submit"
                disabled={status === "loading"}
                className="px-5 py-3 rounded-xl text-sm font-semibold"
                style={{ background: `linear-gradient(135deg, ${ACCENT}, #1D4ED8)`, color: "#fff" }}
              >
                {status === "loading" ? "..." : "Join"}
              </button>
            </form>
          )}
          <p className="text-white/20 text-xs mt-6">AutoReply.io &copy; {new Date().getFullYear()}</p>
        </motion.section>
      </div>
    </div>
  );
}

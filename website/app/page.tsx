import Navbar from "./components/Navbar";
import Footer from "./components/Footer";

const features = [
  { icon: "💬", title: "Auto Comment Replies", desc: "Automatically reply to every comment on your posts with fixed messages or AI-generated responses." },
  { icon: "✉️", title: "Private Auto DMs", desc: "Send a private message to anyone who comments — deliver lead magnets, links, or thank you notes." },
  { icon: "🤖", title: "AI-Powered Replies", desc: "Use GPT-4o to craft contextual, human-like replies. Set a custom prompt to match your brand voice." },
  { icon: "🎯", title: "Keyword Triggers", desc: "Only reply when comments contain specific keywords. Perfect for \"link\", \"price\", \"interested\" triggers." },
  { icon: "⏰", title: "Bulk Reply to Past Comments", desc: "Forgot to set up automation? Reply to all existing comments with random human-like delays.", pro: true },
  { icon: "📊", title: "Dashboard & Analytics", desc: "Track replies sent, active rules, and manage all your pages and accounts from one dashboard." },
];

const steps = [
  { num: "1", title: "Connect Your Accounts", desc: "Login with Facebook and connect your Pages & Instagram business accounts." },
  { num: "2", title: "Pick a Post & Set Rules", desc: "Choose a post or reel, set trigger type (all, keyword, AI) and your reply message." },
  { num: "3", title: "Go Live & Relax", desc: "AutoReply handles every comment 24/7. Get DMs delivered and engagement boosted automatically." },
];

export default function Home() {
  return (
    <>
      <Navbar />

      {/* Hero */}
      <section className="pt-40 pb-20 text-center px-5">
        <div className="max-w-4xl mx-auto">
          <div className="inline-block bg-primary/8 text-primary px-5 py-2 rounded-full text-sm font-semibold mb-6">
            🚀 Trusted by 500+ creators & businesses
          </div>
          <h1 className="text-4xl md:text-6xl font-extrabold leading-tight mb-5">
            Auto-Reply to Every
            <br />
            <span className="bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              Comment & DM
            </span>
          </h1>
          <p className="text-lg text-text-secondary max-w-2xl mx-auto mb-9">
            Never miss a comment again. AutoReply.io automatically responds to
            Facebook & Instagram comments, sends private DMs, and uses AI to
            craft perfect replies — 24/7.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16">
            <a
              href="#"
              className="px-9 py-4 bg-gradient-to-br from-primary to-primary-dark text-white rounded-xl text-lg font-semibold shadow-lg shadow-primary/30 hover:-translate-y-0.5 transition-all"
            >
              Start Free — No Card Required
            </a>
            <a
              href="#how-it-works"
              className="px-9 py-4 border-2 border-primary text-primary rounded-xl text-lg font-semibold hover:bg-primary hover:text-white transition-all"
            >
              See How It Works
            </a>
          </div>
          <div className="flex justify-center gap-12 md:gap-16">
            {[
              ["10M+", "Replies Sent"],
              ["500+", "Active Users"],
              ["4.9★", "User Rating"],
            ].map(([num, label]) => (
              <div key={label} className="flex flex-col">
                <span className="text-2xl md:text-3xl font-extrabold text-primary">{num}</span>
                <span className="text-sm text-text-secondary">{label}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Platform Cards */}
      <section className="pb-20 px-5">
        <div className="max-w-4xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white rounded-2xl p-10 text-center shadow-sm border-2 border-transparent hover:border-blue-500 hover:-translate-y-1 transition-all">
            <div className="text-5xl mb-4">📘</div>
            <h3 className="text-xl font-bold mb-2">Facebook Auto DM</h3>
            <p className="text-text-secondary text-sm">Auto-reply to page post comments and send private messages to engaged users.</p>
          </div>
          <div className="bg-white rounded-2xl p-10 text-center shadow-sm border-2 border-transparent hover:border-pink-500 hover:-translate-y-1 transition-all">
            <div className="text-5xl mb-4">📸</div>
            <h3 className="text-xl font-bold mb-2">Instagram Auto DM</h3>
            <p className="text-text-secondary text-sm">Reply to reel & post comments and DM followers automatically.</p>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="py-20 px-5">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-extrabold text-center mb-3">
            Everything You Need to{" "}
            <span className="bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              Automate Engagement
            </span>
          </h2>
          <p className="text-center text-text-secondary text-lg mb-12">
            Set up once, let AutoReply handle the rest
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {features.map((f) => (
              <div
                key={f.title}
                className="bg-white rounded-2xl p-8 shadow-sm hover:-translate-y-1 transition-transform"
              >
                <div className="text-4xl mb-4">{f.icon}</div>
                <h3 className="text-lg font-bold mb-2">
                  {f.title}
                  {f.pro && (
                    <span className="ml-2 inline-block bg-gradient-to-r from-primary to-secondary text-white text-[11px] font-bold px-2 py-0.5 rounded-md align-middle">
                      PRO
                    </span>
                  )}
                </h3>
                <p className="text-sm text-text-secondary leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" className="py-20 px-5 bg-white">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-extrabold text-center mb-12">
            Set Up in{" "}
            <span className="bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              3 Minutes
            </span>
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-10">
            {steps.map((s) => (
              <div key={s.num} className="text-center">
                <div className="inline-flex items-center justify-center w-14 h-14 bg-gradient-to-br from-primary to-primary-dark text-white text-2xl font-extrabold rounded-2xl mb-5">
                  {s.num}
                </div>
                <h3 className="text-lg font-bold mb-2">{s.title}</h3>
                <p className="text-sm text-text-secondary">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="py-20 px-5">
        <div className="max-w-3xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-extrabold text-center mb-3">
            Simple{" "}
            <span className="bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              Pricing
            </span>
          </h2>
          <p className="text-center text-text-secondary text-lg mb-12">
            Start free, upgrade when you&apos;re ready
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Free */}
            <div className="bg-white rounded-2xl p-10 shadow-sm border-2 border-transparent">
              <div className="text-center mb-7">
                <h3 className="text-xl font-bold mb-2">Free</h3>
                <div className="text-5xl font-extrabold text-primary">₹0</div>
                <p className="text-sm text-text-secondary">Forever free</p>
              </div>
              <ul className="space-y-3 mb-8 text-sm">
                <li>✓ 3 active automation rules</li>
                <li>✓ Fixed message replies</li>
                <li>✓ Keyword triggers</li>
                <li>✓ 100 replies/month</li>
                <li className="text-text-secondary">✗ AI-powered replies</li>
                <li className="text-text-secondary">✗ Auto DMs</li>
                <li className="text-text-secondary">✗ Bulk reply to past comments</li>
              </ul>
              <a href="#" className="block text-center px-6 py-3 border-2 border-primary text-primary rounded-xl font-semibold hover:bg-primary hover:text-white transition-all">
                Get Started Free
              </a>
            </div>

            {/* Pro */}
            <div className="bg-white rounded-2xl p-10 shadow-sm border-2 border-primary relative">
              <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-gradient-to-r from-primary to-secondary text-white text-xs font-bold px-5 py-1.5 rounded-full">
                MOST POPULAR
              </div>
              <div className="text-center mb-7">
                <h3 className="text-xl font-bold mb-2">Pro</h3>
                <div className="text-5xl font-extrabold text-primary">₹999</div>
                <p className="text-sm text-text-secondary">Lifetime access — one-time payment</p>
              </div>
              <ul className="space-y-3 mb-8 text-sm">
                <li>✓ Unlimited automation rules</li>
                <li>✓ Fixed + AI-powered replies</li>
                <li>✓ All trigger types</li>
                <li>✓ Unlimited replies</li>
                <li>✓ Auto DMs on every comment</li>
                <li>✓ Bulk reply to past comments</li>
                <li>✓ Priority support</li>
              </ul>
              <a href="#" className="block text-center px-6 py-3 bg-gradient-to-br from-primary to-primary-dark text-white rounded-xl font-semibold shadow-lg shadow-primary/30 hover:-translate-y-0.5 transition-all">
                Upgrade to Pro
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 px-5 bg-gradient-to-br from-primary to-primary-dark text-white text-center">
        <h2 className="text-3xl md:text-4xl font-extrabold mb-3">
          Ready to Automate Your Replies?
        </h2>
        <p className="text-lg opacity-90 mb-8">
          Join 500+ creators who save hours every week with AutoReply.io
        </p>
        <a
          href="#"
          className="inline-block px-9 py-4 bg-white text-primary rounded-xl text-lg font-semibold shadow-lg hover:-translate-y-0.5 transition-all"
        >
          Get Started Free
        </a>
      </section>

      <Footer />
    </>
  );
}

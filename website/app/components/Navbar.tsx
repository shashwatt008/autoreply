"use client";

import Link from "next/link";
import { useState } from "react";

export default function Navbar() {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <nav className="fixed top-0 left-0 right-0 bg-[#F8F9FE]/90 backdrop-blur-xl z-50 border-b border-primary/8">
      <div className="max-w-6xl mx-auto px-5 py-4 flex items-center justify-between">
        <Link href="/" className="text-xl font-extrabold text-primary">
          ⚡ AutoReply.io
        </Link>

        {/* Desktop */}
        <div className="hidden md:flex items-center gap-7">
          <Link
            href="/#features"
            className="text-sm font-medium text-text-secondary hover:text-primary transition-colors"
          >
            Features
          </Link>
          <Link
            href="/#how-it-works"
            className="text-sm font-medium text-text-secondary hover:text-primary transition-colors"
          >
            How It Works
          </Link>
          <Link
            href="/#pricing"
            className="text-sm font-medium text-text-secondary hover:text-primary transition-colors"
          >
            Pricing
          </Link>
          <Link
            href="/privacy"
            className="text-sm font-medium text-text-secondary hover:text-primary transition-colors"
          >
            Privacy
          </Link>
          <Link
            href="/"
            className="px-5 py-2 bg-gradient-to-br from-primary to-primary-dark text-white rounded-xl text-sm font-semibold shadow-lg shadow-primary/30 hover:-translate-y-0.5 transition-all"
          >
            Get Started
          </Link>
        </div>

        {/* Mobile toggle */}
        <button
          onClick={() => setMenuOpen(!menuOpen)}
          className="md:hidden text-2xl"
        >
          {menuOpen ? "✕" : "☰"}
        </button>
      </div>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="md:hidden bg-white px-5 py-4 flex flex-col gap-4 shadow-lg">
          <Link href="/#features" onClick={() => setMenuOpen(false)} className="text-sm font-medium text-text-secondary">Features</Link>
          <Link href="/#how-it-works" onClick={() => setMenuOpen(false)} className="text-sm font-medium text-text-secondary">How It Works</Link>
          <Link href="/#pricing" onClick={() => setMenuOpen(false)} className="text-sm font-medium text-text-secondary">Pricing</Link>
          <Link href="/privacy" onClick={() => setMenuOpen(false)} className="text-sm font-medium text-text-secondary">Privacy</Link>
          <Link href="/" className="px-5 py-2 bg-gradient-to-br from-primary to-primary-dark text-white rounded-xl text-sm font-semibold text-center">Get Started</Link>
        </div>
      )}
    </nav>
  );
}

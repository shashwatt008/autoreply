import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-[#1a1a2e] text-white py-16">
      <div className="max-w-6xl mx-auto px-5">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-10 mb-10">
          <div className="md:col-span-1">
            <h4 className="text-lg font-bold mb-4">⚡ AutoReply.io</h4>
            <p className="text-sm text-gray-400 leading-relaxed">
              Automate your social media engagement with AI-powered comment
              replies and DMs.
            </p>
          </div>
          <div>
            <h4 className="font-bold mb-4">Product</h4>
            <div className="flex flex-col gap-2">
              <Link href="/#features" className="text-sm text-gray-400 hover:text-primary transition-colors">Features</Link>
              <Link href="/#pricing" className="text-sm text-gray-400 hover:text-primary transition-colors">Pricing</Link>
              <Link href="/#how-it-works" className="text-sm text-gray-400 hover:text-primary transition-colors">How It Works</Link>
            </div>
          </div>
          <div>
            <h4 className="font-bold mb-4">Legal</h4>
            <div className="flex flex-col gap-2">
              <Link href="/privacy" className="text-sm text-gray-400 hover:text-primary transition-colors">Privacy Policy</Link>
              <Link href="/deletion" className="text-sm text-gray-400 hover:text-primary transition-colors">Data Deletion</Link>
              <Link href="/terms" className="text-sm text-gray-400 hover:text-primary transition-colors">Terms of Service</Link>
            </div>
          </div>
          <div>
            <h4 className="font-bold mb-4">Support</h4>
            <a href="mailto:support@autoreply.io" className="text-sm text-gray-400 hover:text-primary transition-colors">
              support@autoreply.io
            </a>
          </div>
        </div>
        <div className="border-t border-white/10 pt-6 text-center">
          <p className="text-xs text-gray-500">
            &copy; 2026 AutoReply.io. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}

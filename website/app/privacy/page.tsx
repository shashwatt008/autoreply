import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy — AutoReply.io",
  description: "How AutoReply.io collects, uses, and protects your data.",
};

export default function Privacy() {
  return (
    <>
      <Navbar />
      <div className="max-w-3xl mx-auto px-5 pt-32 pb-16">
        <h1 className="text-4xl font-extrabold mb-2">Privacy Policy</h1>
        <p className="text-text-secondary text-sm mb-10">Last Updated: March 12, 2026</p>

        <p className="text-text-secondary leading-relaxed mb-8">
          AutoReply.io (&quot;we&quot;, &quot;our&quot;, or &quot;us&quot;) is committed to protecting the privacy of our
          users (&quot;you&quot; or &quot;your&quot;). This Privacy Policy explains how we collect, use,
          disclose, and safeguard your information when you use our application and website.
        </p>

        <Section title="1. Information We Collect">
          <p>When you use AutoReply.io, we collect the following information:</p>
          <ul className="list-disc pl-6 space-y-2 mt-3">
            <li><strong>Facebook Profile Information:</strong> Your name, email address, and Facebook User ID, obtained through Facebook Login (OAuth).</li>
            <li><strong>Facebook Page Data:</strong> Page names, Page IDs, and Page access tokens for pages you choose to connect.</li>
            <li><strong>Instagram Account Data:</strong> Instagram business account username, profile picture, and follower count for accounts linked to your connected Facebook Pages.</li>
            <li><strong>Post & Comment Data:</strong> Post content and comments on your connected pages/accounts, used solely to provide automated reply functionality.</li>
            <li><strong>Payment Information:</strong> Payment transaction IDs processed through Razorpay. We do not store your credit card or bank details — these are handled entirely by Razorpay.</li>
            <li><strong>Usage Data:</strong> Number of automated replies sent, automation rules created, and subscription plan status.</li>
          </ul>
        </Section>

        <Section title="2. How We Use Your Information">
          <p>We use the collected information exclusively for:</p>
          <ul className="list-disc pl-6 space-y-2 mt-3">
            <li>Authenticating your identity via Facebook Login</li>
            <li>Displaying and managing your connected Facebook Pages and Instagram accounts</li>
            <li>Fetching posts and comments to enable automated reply features</li>
            <li>Sending automated comment replies and direct messages on your behalf, as configured by you</li>
            <li>Processing subscription payments via Razorpay</li>
            <li>Tracking usage limits based on your subscription plan</li>
            <li>Communicating with you about your account and service updates</li>
          </ul>
        </Section>

        <Section title="3. Facebook & Instagram Data Usage">
          <p>We access Facebook and Instagram data through Meta&apos;s Graph API. Specifically:</p>
          <ul className="list-disc pl-6 space-y-2 mt-3">
            <li><strong>We DO:</strong> Read your pages, posts, and comments. Post replies to comments on your behalf. Send private messages/DMs on your behalf when you enable this feature.</li>
            <li><strong>We DO NOT:</strong> Sell, rent, or share your Facebook/Instagram data with any third parties. Post content to your pages without your explicit configuration. Access data from pages or accounts you haven&apos;t connected. Store comment content permanently — it is processed in real-time.</li>
          </ul>
        </Section>

        <Section title="4. Data Storage & Security">
          <ul className="list-disc pl-6 space-y-2">
            <li>Your data is stored securely in our database hosted on Supabase (PostgreSQL) with Row-Level Security enabled.</li>
            <li>All API communications are encrypted using HTTPS/TLS.</li>
            <li>Facebook/Instagram access tokens are stored server-side only and are never exposed to client applications.</li>
            <li>We use industry-standard security practices including JWT authentication, CORS protection, and encrypted credentials.</li>
          </ul>
        </Section>

        <Section title="5. Data Sharing">
          <p>We do not sell, trade, or transfer your personal information to third parties. We share data only with:</p>
          <ul className="list-disc pl-6 space-y-2 mt-3">
            <li><strong>Meta (Facebook/Instagram):</strong> To authenticate your account and perform API operations (posting replies, sending messages) as configured by you.</li>
            <li><strong>OpenAI:</strong> If you use AI-powered replies, your comment text is sent to OpenAI&apos;s API to generate responses. No personal identifiers are sent.</li>
            <li><strong>Razorpay:</strong> For processing payments. Razorpay has its own privacy policy.</li>
          </ul>
        </Section>

        <Section title="6. Data Retention">
          <ul className="list-disc pl-6 space-y-2">
            <li>Your account data is retained as long as your account is active.</li>
            <li>Comment and post data is processed in real-time and not stored permanently.</li>
            <li>If you delete your account, all associated data (pages, rules, tokens) will be permanently deleted within 30 days.</li>
            <li>You can request immediate data deletion at any time — see our <a href="/deletion" className="text-primary hover:underline">Data Deletion page</a>.</li>
          </ul>
        </Section>

        <Section title="7. Your Rights">
          <p>You have the right to:</p>
          <ul className="list-disc pl-6 space-y-2 mt-3">
            <li><strong>Access:</strong> Request a copy of the data we hold about you.</li>
            <li><strong>Correction:</strong> Request correction of inaccurate data.</li>
            <li><strong>Deletion:</strong> Request deletion of your account and all associated data via our <a href="/deletion" className="text-primary hover:underline">Data Deletion page</a>.</li>
            <li><strong>Revoke Access:</strong> Remove AutoReply.io from your Facebook App settings at any time, which will revoke our access to your data.</li>
            <li><strong>Withdraw Consent:</strong> Disconnect individual pages or accounts from the app dashboard.</li>
          </ul>
        </Section>

        <Section title="8. Cookies">
          <p>Our website uses minimal cookies for essential functionality (session management). We do not use tracking cookies or third-party analytics cookies.</p>
        </Section>

        <Section title="9. Children's Privacy">
          <p>AutoReply.io is not intended for use by individuals under the age of 18. We do not knowingly collect information from children.</p>
        </Section>

        <Section title="10. Changes to This Policy">
          <p>We may update this Privacy Policy from time to time. We will notify users of significant changes via email or in-app notification. Continued use of the service after changes constitutes acceptance of the updated policy.</p>
        </Section>

        <Section title="11. Contact Us">
          <p>
            If you have questions about this Privacy Policy or our data practices, contact us at:{" "}
            <a href="mailto:support@autoreply.io" className="text-primary hover:underline">
              support@autoreply.io
            </a>
          </p>
        </Section>
      </div>
      <Footer />
    </>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="mb-8">
      <h2 className="text-xl font-bold mb-3">{title}</h2>
      <div className="text-[15px] text-[#4a4a4a] leading-relaxed">{children}</div>
    </div>
  );
}

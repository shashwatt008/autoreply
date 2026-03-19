import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service — AutoReply.io",
  description: "Terms and conditions for using AutoReply.io.",
};

export default function Terms() {
  return (
    <>
      <Navbar />
      <div className="max-w-3xl mx-auto px-5 pt-32 pb-16">
        <h1 className="text-4xl font-extrabold mb-2">Terms of Service</h1>
        <p className="text-text-secondary text-sm mb-10">Last Updated: March 12, 2026</p>

        <p className="text-[15px] text-[#4a4a4a] leading-relaxed mb-8">
          By using AutoReply.io (&quot;the Service&quot;), you agree to the following terms. If you
          do not agree, please do not use the Service.
        </p>

        <Section title="1. Service Description">
          <p>
            AutoReply.io is a social media automation tool that allows users to set up automated
            comment replies and direct messages on Facebook Pages and Instagram business accounts.
            The Service operates through Meta&apos;s official Graph API.
          </p>
        </Section>

        <Section title="2. Account & Eligibility">
          <ul className="list-disc pl-6 space-y-2">
            <li>You must be at least 18 years old to use this Service.</li>
            <li>You must have a valid Facebook account and admin access to the Pages/Instagram accounts you connect.</li>
            <li>You are responsible for maintaining the security of your account credentials.</li>
            <li>One user account per Facebook account.</li>
          </ul>
        </Section>

        <Section title="3. Acceptable Use">
          <p>You agree NOT to use AutoReply.io to:</p>
          <ul className="list-disc pl-6 space-y-2 mt-3">
            <li>Send spam, unsolicited messages, or abusive content</li>
            <li>Violate Meta&apos;s (Facebook/Instagram) Terms of Service or Community Standards</li>
            <li>Harass, impersonate, or deceive other users</li>
            <li>Automate activity on accounts you do not own or manage</li>
            <li>Distribute malware, phishing links, or harmful content</li>
            <li>Circumvent rate limits or abuse the platform API</li>
          </ul>
          <p className="mt-3">We reserve the right to suspend or terminate accounts that violate these terms without notice.</p>
        </Section>

        <Section title="4. Subscription & Payments">
          <ul className="list-disc pl-6 space-y-2">
            <li><strong>Free Plan:</strong> Limited to 3 automation rules, 100 replies/month, and fixed message replies only.</li>
            <li><strong>Pro Plan:</strong> One-time lifetime payment of ₹999 (or equivalent). Unlocks all features including AI replies, auto DMs, bulk reply, and unlimited rules.</li>
            <li>Payments are processed securely through Razorpay. We do not store your payment card details.</li>
            <li><strong>Refund Policy:</strong> Refunds are available within 7 days of purchase if you have not used any Pro features. Contact support@autoreply.io for refund requests.</li>
          </ul>
        </Section>

        <Section title="5. API & Third-Party Dependencies">
          <p>AutoReply.io depends on Meta&apos;s Graph API and OpenAI&apos;s API. We are not responsible for:</p>
          <ul className="list-disc pl-6 space-y-2 mt-3">
            <li>Changes to Meta&apos;s API, policies, or rate limits that may affect functionality</li>
            <li>Downtime or outages from Meta, OpenAI, or our hosting providers</li>
            <li>Facebook or Instagram restricting your account due to automated activity</li>
          </ul>
        </Section>

        <Section title="6. Limitation of Liability">
          <p>AutoReply.io is provided &quot;as is&quot; without warranties of any kind. We are not liable for:</p>
          <ul className="list-disc pl-6 space-y-2 mt-3">
            <li>Any loss of engagement, followers, or revenue resulting from use of the Service</li>
            <li>Account restrictions imposed by Facebook or Instagram</li>
            <li>Data loss due to service disruptions</li>
            <li>Indirect, incidental, or consequential damages</li>
          </ul>
        </Section>

        <Section title="7. Intellectual Property">
          <p>
            All content, design, and code of AutoReply.io are owned by us. You retain ownership of
            your social media content. By using the Service, you grant us a limited license to access
            and interact with your content solely for providing the automation features you configure.
          </p>
        </Section>

        <Section title="8. Account Termination">
          <p>
            You may delete your account at any time via our{" "}
            <a href="/deletion" className="text-primary hover:underline">Data Deletion page</a>.
            We may terminate accounts that violate these terms. Upon termination, all your data will
            be permanently deleted within 30 days.
          </p>
        </Section>

        <Section title="9. Changes to Terms">
          <p>
            We may modify these terms at any time. Continued use of the Service after changes
            constitutes acceptance. We will notify users of material changes via email.
          </p>
        </Section>

        <Section title="10. Governing Law">
          <p>
            These terms are governed by the laws of India. Any disputes shall be subject to the
            exclusive jurisdiction of the courts in India.
          </p>
        </Section>

        <Section title="11. Contact">
          <p>
            Questions? Contact us at{" "}
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

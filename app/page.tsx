import HeroSection from '@/components/hero-section'
import FeaturesSection from '@/components/features-7'
import ContentSection from '@/components/content-2'
import IntegrationsSection from '@/components/integrations-8'
import Pricing from '@/components/pricing'
import FooterSection from '@/components/footer'

export default function Home() {
  return (
    <div className="min-h-screen">
      <HeroSection />
      <ContentSection />
      <IntegrationsSection />
      <FeaturesSection />
      <Pricing />
      <FooterSection />
    </div>
  );
}

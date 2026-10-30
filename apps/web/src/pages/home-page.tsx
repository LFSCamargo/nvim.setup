import { Docs } from '@/components/sections/docs';
import { Help } from '@/components/sections/help';
import { Hero } from '@/components/sections/hero';
import { Install } from '@/components/sections/install';
import { Nav } from '@/components/sections/nav';
import { Principles } from '@/components/sections/principles';
import { SiteFooter } from '@/components/sections/site-footer';
import { Workspace } from '@/components/sections/workspace';
import { ScreenshotDialog } from '@/components/screenshot-dialog';
import { useDocumentMeta } from '@/hooks/use-document-meta';
import { useScreenshotLightbox } from '@/hooks/use-screenshot-lightbox';
import { homeMeta } from '@/lib/seo';

export function HomePage() {
  const lightbox = useScreenshotLightbox();
  useDocumentMeta(homeMeta());

  return (
    <>
      <a
        className="fixed top-[-100px] left-5 z-50 bg-white px-3 py-3 text-black focus:top-3"
        href="#main"
      >
        Skip to content
      </a>
      <Nav />
      <main id="main" className="overflow-x-hidden">
        <Hero onOpenScreenshot={lightbox.open} />
        <Principles />
        <Workspace onOpenScreenshot={lightbox.open} />
        <Install />
        <Docs />
        <Help />
      </main>
      <SiteFooter />
      <ScreenshotDialog
        index={lightbox.index}
        open={lightbox.isOpen}
        closeRef={lightbox.closeRef}
        onClose={lightbox.close}
        onIndexChange={lightbox.setIndex}
      />
    </>
  );
}

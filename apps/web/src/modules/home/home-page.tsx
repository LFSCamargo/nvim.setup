import { Docs } from '@/modules/home/sections/docs';
import { Help } from '@/modules/home/sections/help';
import { Hero } from '@/modules/home/sections/hero';
import { Install } from '@/modules/home/sections/install';
import { Nav } from '@/shared/components/nav';
import { Principles } from '@/modules/home/sections/principles';
import { SiteFooter } from '@/shared/components/site-footer';
import { Workspace } from '@/modules/home/sections/workspace';
import { ScreenshotDialog } from '@/modules/home/components/screenshots/screenshot-dialog';
import { useDocumentMeta } from '@/shared/hooks/use-document-meta';
import { useScreenshotLightbox } from '@/modules/home/components/screenshots/use-screenshot-lightbox';
import { homeMeta } from '@/shared/utils/seo';

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

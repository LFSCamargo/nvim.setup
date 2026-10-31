import { useLayoutEffect } from 'react';
import { applyPageMeta, type PageMeta } from '@/shared/seo/seo';

export function useDocumentMeta(meta: PageMeta) {
  useLayoutEffect(() => {
    applyPageMeta(meta);
  }, [meta.title, meta.description, meta.path, meta.type]);
}

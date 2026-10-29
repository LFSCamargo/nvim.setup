import { InfiniteMarquee } from '@/components/ui/infinite-marquee';

const items = [
  'A LITTLE LESS FRICTION.',
  'Files ↗',
  'Code ↗',
  'Git ↗',
  'AI ↗',
  'A LOT MORE FLOW.',
];

export function Principles() {
  return (
    <InfiniteMarquee
      aria-label="A little less friction. Files, code, Git, AI. A lot more flow."
      className="border-y border-line py-6"
    >
      {items.map((item) => (
        <span
          key={item}
          className={
            item.includes('FRICTION') || item.includes('FLOW')
              ? 'font-mono text-[10px] tracking-[0.16em] text-muted'
              : 'text-lg text-foreground/80'
          }
        >
          {item}
        </span>
      ))}
    </InfiniteMarquee>
  );
}

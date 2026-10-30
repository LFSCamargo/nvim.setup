# Third-party UI source

The landing page adapts these **Aceternity UI** components by **Manu Arora**:

| Component             | Source                                                     |
| --------------------- | ---------------------------------------------------------- |
| Liquid Glass          | https://ui.aceternity.com/components/liquid-glass          |
| Spotlight New         | https://ui.aceternity.com/components/spotlight-new         |
| Flip Words            | https://ui.aceternity.com/components/flip-words            |
| Text Generate Effect  | https://ui.aceternity.com/components/text-generate-effect  |
| Glowing Effect        | https://ui.aceternity.com/components/glowing-effect        |
| Hover Border Gradient | https://ui.aceternity.com/components/hover-border-gradient |
| Code Block            | https://ui.aceternity.com/components/code-block            |

Registry JSON: `https://ui.aceternity.com/registry/<name>.json`. Terms: https://ui.aceternity.com/terms.

Adaptations: grayscale gradients, Tailwind v4 + local CSS classes, TypeScript, reduced-motion / reduced-transparency fallbacks, and a refraction failure fallback on Liquid Glass. The Code Block is a first-party grayscale terminal sample (copy, line numbers, wrapping) inspired by that component; it does not bundle `react-syntax-highlighter` or Tabler icons. The fetched registry attributes the components to Manu Arora but does not embed a license header. This notice preserves that attribution; it does not assign a new license to those components.

React, Motion, Vite, Tailwind CSS, and the testing libraries are installed dependencies governed by their respective distributed licenses. Google Fonts serves DM Sans, DM Serif Display, and IBM Plex Mono; system font fallbacks remain available when font requests are blocked.

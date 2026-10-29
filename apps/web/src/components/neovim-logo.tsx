type NeovimLogoProps = {
  className?: string;
};

export function NeovimLogo({ className }: NeovimLogoProps) {
  return (
    <svg
      viewBox="0 0 602 588"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
      className={className}
    >
      <path
        fill="currentColor"
        d="M0 0.1 177.7 216.9v218.2L0 588.2V0.1zm244.2 216.6L421.9 0.1h157.5L244.2 434.9zM601.9 369.8v218.3H444.4L244.2 434.9z"
      />
    </svg>
  );
}

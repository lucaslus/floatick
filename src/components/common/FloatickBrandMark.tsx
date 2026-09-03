import React from "react";

interface FloatickBrandMarkProps {
  size?: number;
  className?: string;
  withGlow?: boolean;
}

export const FloatickBrandMark: React.FC<FloatickBrandMarkProps> = ({
  size = 36,
  className = "",
  withGlow = true,
}) => {
  const radius = Math.round(size * 0.31);
  const strokeWidth = size * 0.075;

  return (
    <div className={`relative shrink-0 flex items-center justify-center ${className}`}>
      {/* Ambient background glow aura */}
      {withGlow && (
        <div
          style={{
            width: size * 1.6,
            height: size * 1.6,
            filter: "blur(12px)",
          }}
          className="absolute -inset-1 rounded-full bg-teal-500/20 dark:bg-[#20B8A8]/25 pointer-events-none opacity-80"
        />
      )}

      {/* Brand Badge Surface */}
      <div
        style={{
          width: size,
          height: size,
          borderRadius: radius,
          background: "linear-gradient(145deg, #263C40 0%, #152023 100%)",
          boxShadow: "inset 0 1px 1px 0 rgba(255, 255, 255, 0.2), 0 3px 10px -2px rgba(0, 0, 0, 0.4)",
          border: "1px solid rgba(64, 95, 98, 0.85)",
        }}
        className="relative overflow-hidden flex items-center justify-center"
      >
        <svg
          width={size}
          height={size}
          viewBox="0 0 100 100"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="absolute inset-0"
        >
          {/* Back Checkmark */}
          <path
            d="M22 50 C27 54, 31 59, 36 64 C41 59, 47 52, 53 46"
            stroke="#1DB3A8"
            strokeWidth={strokeWidth * 2.6}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          {/* Front Checkmark with glow highlight */}
          <path
            d="M38 50 C43 55, 47 60, 52 64 C60 55, 68 46, 77 37"
            stroke="#34E5D4"
            strokeWidth={strokeWidth * 2.6}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </div>
    </div>
  );
};

import React from "react";

interface FloatickBrandMarkProps {
  size?: number;
  className?: string;
}

export const FloatickBrandMark: React.FC<FloatickBrandMarkProps> = ({
  size = 32,
  className = "",
}) => {
  const radius = Math.round(size * 0.3);
  const strokeWidth = size * 0.08;

  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: radius,
        background: "linear-gradient(145deg, #223538 0%, #141E21 100%)",
        border: "1px solid rgba(45, 212, 191, 0.25)",
        boxShadow: "0 1px 3px rgba(0, 0, 0, 0.3)",
      }}
      className={`relative shrink-0 overflow-hidden flex items-center justify-center ${className}`}
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
          stroke="#14B8A6"
          strokeWidth={strokeWidth * 2.5}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        {/* Front Checkmark */}
        <path
          d="M38 50 C43 55, 47 60, 52 64 C60 55, 68 46, 77 37"
          stroke="#2DD4BF"
          strokeWidth={strokeWidth * 2.5}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
};

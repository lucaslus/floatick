import React from "react";

interface FloatickBrandMarkProps {
  size?: number;
  className?: string;
}

export const FloatickBrandMark: React.FC<FloatickBrandMarkProps> = ({
  size = 36,
  className = "",
}) => {
  const radius = Math.round(size * 0.31);
  const strokeWidth = size * 0.075;

  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: radius,
        background: "linear-gradient(135deg, #24383C 0%, #172326 100%)",
        border: "1px solid rgba(64, 87, 90, 0.92)",
        boxShadow: "0 2px 8px rgba(0, 0, 0, 0.25)",
      }}
      className={`shrink-0 flex items-center justify-center relative overflow-hidden ${className}`}
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
        {/* Front Checkmark */}
        <path
          d="M38 50 C43 55, 47 60, 52 64 C60 55, 68 46, 77 37"
          stroke="#2CCCBD"
          strokeWidth={strokeWidth * 2.6}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
};

{ prev, ... }:

prev.sunshine.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    (prev.fetchurl {
      url = "https://github.com/LizardByte/Sunshine/commit/40ae6c800274afff664838cc48386e01fcffe2cd.patch";
      hash = "sha256-EwMFjGiElxx9rh8r8SLc+e2WrmQyiGSkQ4ldkJ/T3ls=";
    })
  ];
})

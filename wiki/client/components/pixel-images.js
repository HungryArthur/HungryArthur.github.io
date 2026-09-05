export function pixelPerfectGeometry(sourceWidth, sourceHeight, boxWidth, boxHeight = boxWidth) {
  const width = Math.max(1, Math.round(Number(sourceWidth) || 1));
  const height = Math.max(1, Math.round(Number(sourceHeight) || 1));
  const limitWidth = Math.max(1, Math.floor(boxWidth));
  const limitHeight = Math.max(1, Math.floor(boxHeight));

  if (width <= limitWidth && height <= limitHeight) {
    const scale = Math.max(1, Math.floor(Math.min(limitWidth / width, limitHeight / height)));
    return { width: width * scale, height: height * scale, scale };
  }

  let divisor = Math.max(Math.ceil(width / limitWidth), Math.ceil(height / limitHeight));
  while (divisor <= Math.min(width, height)) {
    if (width % divisor === 0 && height % divisor === 0) {
      const drawWidth = width / divisor;
      const drawHeight = height / divisor;
      if (drawWidth <= limitWidth && drawHeight <= limitHeight) {
        return { width: drawWidth, height: drawHeight, scale: 1 / divisor };
      }
    }
    divisor += 1;
  }

  const scale = Math.min(limitWidth / width, limitHeight / height);
  return {
    width: Math.max(1, Math.floor(width * scale)),
    height: Math.max(1, Math.floor(height * scale)),
    scale,
  };
}

export function fitLoadedPixelImage(image, boxSize, firstFrame = false) {
  const sourceWidth = firstFrame && image.naturalWidth > image.naturalHeight && image.naturalWidth % image.naturalHeight === 0
    ? image.naturalHeight
    : image.naturalWidth;
  const geometry = pixelPerfectGeometry(sourceWidth, image.naturalHeight, boxSize);
  image.style.width = `${image.naturalWidth * geometry.scale}px`;
  image.style.height = `${image.naturalHeight * geometry.scale}px`;
  image.style.margin = '0';
  image.style.objectFit = 'none';
  if (firstFrame) {
    image.style.position = 'absolute';
    image.style.left = `${(boxSize - geometry.width) / 2}px`;
    image.style.top = `${(boxSize - geometry.height) / 2}px`;
  }
}

function fitStandalonePixelImage(image) {
  if (!(image instanceof HTMLImageElement) || image.closest('.item-icon, .boss-portrait')) return;
  if (image.dataset.pixelFitted === 'true') return;
  const source = image.currentSrc || image.getAttribute('src') || '';
  if (!source.includes('/assets/textures/')) return;
  if (!image.complete || !image.naturalWidth || !image.naturalHeight) {
    image.addEventListener('load', () => fitStandalonePixelImage(image), { once: true });
    return;
  }

  const computed = getComputedStyle(image);
  const boxWidth = Math.max(1, Math.round(Number.parseFloat(computed.width) || image.width));
  const boxHeight = Math.max(1, Math.round(Number.parseFloat(computed.height) || image.height));
  const geometry = pixelPerfectGeometry(image.naturalWidth, image.naturalHeight, boxWidth, boxHeight);
  const horizontalPadding = Math.max(0, boxWidth - geometry.width);
  const verticalPadding = Math.max(0, boxHeight - geometry.height);
  image.style.boxSizing = 'content-box';
  image.style.width = `${geometry.width}px`;
  image.style.height = `${geometry.height}px`;
  image.style.paddingLeft = `${Math.floor(horizontalPadding / 2)}px`;
  image.style.paddingRight = `${Math.ceil(horizontalPadding / 2)}px`;
  image.style.paddingTop = `${Math.floor(verticalPadding / 2)}px`;
  image.style.paddingBottom = `${Math.ceil(verticalPadding / 2)}px`;
  image.style.objectFit = 'fill';
  image.dataset.pixelFitted = 'true';
}

function fitStandalonePixelImages(root = document) {
  if (root instanceof HTMLImageElement) fitStandalonePixelImage(root);
  root.querySelectorAll?.('img[src*="/assets/textures/"]').forEach(fitStandalonePixelImage);
}

export function observePixelImages() {
  fitStandalonePixelImages();
  const observer = new MutationObserver((records) => {
    records.forEach((record) => record.addedNodes.forEach((node) => {
      if (node instanceof Element) fitStandalonePixelImages(node);
    }));
  });
  observer.observe(document.body, { childList: true, subtree: true });
  return observer;
}

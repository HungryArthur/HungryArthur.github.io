export function balanceNumber(value) {
  if (!Number.isFinite(value)) return 0;
  return Math.round(value * 100) / 100;
}

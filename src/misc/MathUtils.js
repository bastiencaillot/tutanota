// @flow

export function mod(n: number, m: number): number {
	return ((n % m) + m) % m;
}

/**
 * Clamp value to between min and max (inclusive). Min must be <= Max
 */
export function clamp(value: number, min: number, max: number): number {
	return Math.max(min, Math.min(value, max))
}
import type { range } from './range';

export type kind = 'safe' | 'warning' | 'error';

export type check = {
	kind: kind;
	range: range;
	messages?: string;
};

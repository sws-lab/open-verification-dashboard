import type { check } from './check';
import type { range } from './range';

export type kind =
	| 'NoConflictSafe'
	| 'NoConflictWarning'
	| 'NoConflictError'
	| 'Unchecked'
	| 'OnlyOneProofObligation'
	| 'SafetyW1'
	| 'SafetyW2'
	| 'PrecisionW1'
	| 'PrecisionW2'
	| 'ErrorLevel';

export type Conflict = {
	kind: kind;
	range: range;
	from_po1: check[];
	from_po2: check[];
};

export type DashboardOutput = {
	conflicts: Conflict[];
	po1_name: string;
	po2_name: string;
	sources: string[];
};

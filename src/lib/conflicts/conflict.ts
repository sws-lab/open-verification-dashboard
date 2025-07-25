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
	conflicts: Record<string, Conflict[]>;
	po1_name: string;
	po2_name: string;
};

export function conflictSeverity(kind: Conflict['kind']): 'warning' | 'error' | 'hint' {
	switch (kind) {
		case 'NoConflictSafe':
			return 'hint';
		case 'NoConflictWarning':
			return 'hint';
		case 'NoConflictError':
			return 'hint';
		case 'Unchecked':
			return 'error';
		case 'OnlyOneProofObligation':
			return 'error';
		case 'SafetyW1':
			return 'error';
		case 'SafetyW2':
			return 'error';
		case 'PrecisionW1':
			return 'hint';
		case 'PrecisionW2':
			return 'hint';
		case 'ErrorLevel':
			return 'warning';
		default:
			console.warn(`Unknown conflict kind: ${kind}`);
			return 'warning';
	}
}

export function conflictMessage(conflict: Conflict): string {
	switch (conflict.kind) {
		case 'NoConflictSafe':
			return 'Both analyser agree that this is safe';
		case 'NoConflictWarning':
			return 'Both analyser agree that this is a warning';
		case 'NoConflictError':
			return 'Both analyser agree that this is an error';
		case 'Unchecked':
			return 'This conflict has not been checked yet';
		case 'OnlyOneProofObligation':
			return `Only ${conflict.from_po1.length == 0 ? 'the first' : 'the second'} analyser has a proof obligation for this conflict`;
		case 'PrecisionW1':
			return 'The first analyser is more precise than the second one regarding safety';
		case 'PrecisionW2':
			return 'The second analyser is more precise than the first one regarding safety';
		case 'SafetyW1':
			return 'Only the first analyser says that this is safe';
		case 'SafetyW2':
			return 'Only the second analyser says that this is safe';
		case 'ErrorLevel':
			return 'The two analysers disagree on the error level of this conflict';
		default:
			console.warn(`Unknown conflict kind: ${conflict.kind}`);
			return 'Unknown conflict kind';
	}
}

export function conflictCategory(conflict: Conflict): string {
	if (conflict.from_po1.length > 0) {
		return conflict.from_po1[0].title;
	} else if (conflict.from_po2.length > 0) {
		return conflict.from_po2[0].title;
	} else {
		return 'Unknown source';
	}
}

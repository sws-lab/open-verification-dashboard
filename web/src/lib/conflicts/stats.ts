import type { Conflict } from './conflict';

export type Stats = {
	[file: string]: {
		totalSafe: number;
		totalWarning: number;
		totalError: number;
		agreeOnSafe: number;
		agreeOnWarning: number;
		agreeOnError: number;
		disagreement: number;
		onlyOneChecked: number;
	};
};

function worseCheckOf(conflict: Conflict['from_po1']): string {
	if (conflict.length === 0) return 'safe';
	let worse_check = conflict[0].kind;
	for (const check of conflict) {
		if (check.kind === 'error') {
			worse_check = 'error';
			break;
		} else if (check.kind === 'warning' && worse_check !== 'error') {
			worse_check = 'warning';
		}
	}
	return worse_check;
}

function worseCheck(from_po1: Conflict['from_po1'], from_po2: Conflict['from_po2']): string {
	const checks = from_po1.length === 0 ? from_po2 : from_po1;
	return worseCheckOf(checks);
}

export function calculateStats(conflicts: Conflict[]) {
	const stats = {
		totalSafe: 0,
		totalWarning: 0,
		totalError: 0,
		agreeOnSafe: 0,
		agreeOnWarning: 0,
		agreeOnError: 0,
		disagreement: 0,
		onlyOneChecked: 0
	};

	function incrementCategory(category: string) {
		if (category === 'safe') stats.totalSafe++;
		else if (category === 'warning') stats.totalWarning++;
		else if (category === 'error') stats.totalError++;
	}

	for (const conflict of conflicts) {
		switch (conflict.kind) {
			case 'NoConflictSafe':
				stats.totalSafe++;
				stats.agreeOnSafe++;
				break;
			case 'NoConflictWarning':
				stats.totalWarning++;
				stats.agreeOnWarning++;
				break;
			case 'NoConflictError':
				stats.totalError++;
				stats.agreeOnError++;
				break;
			case 'Unchecked':
				break;
			case 'OnlyOneProofObligation':
				incrementCategory(worseCheck(conflict.from_po1, conflict.from_po2));
				stats.onlyOneChecked++;
				break;
			case 'SafetyW1':
				stats.totalSafe++;
				incrementCategory(worseCheckOf(conflict.from_po2));
				break;
			case 'SafetyW2':
				stats.totalSafe++;
				incrementCategory(worseCheckOf(conflict.from_po1));
				break;
			case 'PrecisionW1':
			case 'PrecisionW2':
				stats.totalSafe++;
				incrementCategory(worseCheckOf(conflict.from_po2));
				incrementCategory(worseCheckOf(conflict.from_po1));
				break;
			case 'ErrorLevel':
				incrementCategory(worseCheckOf(conflict.from_po2));
				incrementCategory(worseCheckOf(conflict.from_po1));
				break;
		}
	}
	return stats;
}

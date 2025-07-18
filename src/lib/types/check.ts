import type {range} from "./range";

export type kind = "safe" | "warning" | "error"
export type category = 
	| "Assertion failure"
    | "Invalid memory access"
    | "Division by zero"
    | "Integer overflow"
    | "Invalid pointer comparison"
    | "Invalid pointer subtraction"
    | "Double free"
    | "Negative array size"
    | "Invalid floating point operation"
    | "Stub condition"
    | "Insufficient variadic arguments"
    | "Insufficient format arguments"
    | "Invalid type of format argument"
    | "Floating-point division by zero"
    | "Floating-point overflow"

export type check = {
	category: category;
	kind: kind;
	range: range;
	message?: string;
}
type file_position = {
	line: number;
	column: number;
};

export type range = {
	start: file_position;
	end: file_position;
	file: string;
};

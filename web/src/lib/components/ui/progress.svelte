<script lang="ts">
	interface Props {
		value: number;
		max: number;
		'aria-label': string;
		id?: string;
	}

	let { value, max, 'aria-label': ariaLabel, id }: Props = $props();
	let percentage = $derived(max > 0 ? (value / max) * 100 : 0);
</script>

<div
	class="progress"
	aria-valuemin="0"
	aria-valuemax={max}
	aria-valuenow={value}
	aria-label="{ariaLabel} ({value}/{max}: {percentage}%)"
	{id}
>
	<div class="progress__bar" style="width: {percentage}%;">&nbsp;</div>
	<p class="progress__label" aria-label="Progress percentage">
		{percentage}%
	</p>
</div>

<style lang="scss">
	.progress {
		border: 1px solid #8f8f9d;
		border-radius: 4px;
		background-color: #e9e9ed;
		position: relative;
		min-width: 8em;
		width: 100%;
		height: 0.7rem;
		overflow: hidden;

		&__bar {
			background-color: var(--primary-color);
			height: 100%;
			transition: width 0.3s ease;
		}

		&__label {
			position: absolute;
			top: 50%;
			left: 50%;
			transform: translate(-50%, -50%);
			font-size: 0.6rem;
			color: var(--text-color);
		}
	}
</style>

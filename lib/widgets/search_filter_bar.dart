import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../theme/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final bloc = context.read<JobBloc>();
        final categories = [
          'All',
          'High Fit (90%+)',
          'Saved (${state.totalSavedCount})',
          'Applied (${state.totalAppliedCount})',
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input & Remote Toggle
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;

                  final searchField = TextField(
                    onChanged: (q) => bloc.add(SearchQueryChanged(q)),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textMuted, size: 20),
                      hintText: isNarrow
                          ? 'Search jobs, skills, or companies...'
                          : 'Search by title, skill (e.g., Flutter, Postgres, AI), or company...',
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  bloc.add(SearchQueryChanged('')),
                            )
                          : null,
                    ),
                  );

                  final remoteToggle = InkWell(
                    onTap: () => bloc.add(FilterRemoteOnlyToggled()),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: state.filterRemoteOnly
                            ? AppColors.primary.withAlpha(40)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.filterRemoteOnly
                              ? AppColors.primary
                              : AppColors.surfaceBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public,
                              size: 16,
                              color: state.filterRemoteOnly
                                  ? AppColors.primary
                                  : AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Remote',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: state.filterRemoteOnly
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        searchField,
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: remoteToggle),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 12),
                      remoteToggle,
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Category Pills & Match Slider
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;

                  final categoryPills = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final normalizedCat = cat.startsWith('Saved')
                            ? 'Saved'
                            : cat.startsWith('Applied')
                                ? 'Applied'
                                : cat;
                        final isSelected =
                            state.selectedCategory == normalizedCat;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                bloc.add(CategoryChanged(normalizedCat));
                              }
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceElevated,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceBorder,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );

                  final matchSlider = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Min Match:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${state.minMatchScore}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            thumbColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surfaceBorder,
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: state.minMatchScore.toDouble(),
                            min: 50,
                            max: 95,
                            divisions: 9,
                            onChanged: (val) => bloc
                                .add(MinMatchScoreChanged(val.toInt())),
                          ),
                        ),
                      ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: categoryPills),
                        const SizedBox(width: 12),
                        matchSlider,
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      categoryPills,
                      const SizedBox(height: 10),
                      matchSlider,
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

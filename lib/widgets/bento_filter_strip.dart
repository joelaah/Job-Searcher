import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../theme/app_colors.dart';

class BentoFilterStrip extends StatelessWidget {
  const BentoFilterStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final bloc = context.read<JobBloc>();
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 1000;

        final categories = [
          'All',
          '🎯 High Fit (90%+)',
          '💾 Saved (${state.totalSavedCount})',
          '⚡ Applied (${state.totalAppliedCount})',
        ];

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.bentoCardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.bentoBorder, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Search Bar & Remote Toggle
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: state.searchQuery)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: state.searchQuery.length),
                          ),
                        onChanged: (q) => bloc.add(SearchQueryChanged(q)),
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Semantic search by title, tech stack (e.g. Flutter, pgvector, Python), or company...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                          suffixIcon: state.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                  onPressed: () => bloc.add(SearchQueryChanged('')),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Remote Toggle Button
                  InkWell(
                    onTap: () => bloc.add(FilterRemoteOnlyToggled()),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: state.filterRemoteOnly ? AppColors.primary.withAlpha(40) : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: state.filterRemoteOnly ? AppColors.primary : AppColors.surfaceBorder,
                          width: state.filterRemoteOnly ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.public,
                            size: 16,
                            color: state.filterRemoteOnly ? AppColors.primary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remote Only',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: state.filterRemoteOnly ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Filter Chips & Score Slider Row
              if (isDesktop)
                Row(
                  children: [
                    // Category Chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final normalizedCat = cat.startsWith('💾 Saved')
                                ? 'Saved'
                                : cat.startsWith('⚡ Applied')
                                    ? 'Applied'
                                    : cat.startsWith('🎯 High Fit')
                                        ? 'High Fit (90%+)'
                                        : cat;
                            final isSelected = state.selectedCategory == normalizedCat;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) bloc.add(CategoryChanged(normalizedCat));
                                },
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.surfaceElevated,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Min Match Score Slider
                    _buildScoreSlider(context, bloc, state),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final normalizedCat = cat.startsWith('💾 Saved')
                              ? 'Saved'
                              : cat.startsWith('⚡ Applied')
                                  ? 'Applied'
                                  : cat.startsWith('🎯 High Fit')
                                      ? 'High Fit (90%+)'
                                      : cat;
                          final isSelected = state.selectedCategory == normalizedCat;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (sel) {
                                if (sel) bloc.add(CategoryChanged(normalizedCat));
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceElevated,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildScoreSlider(context, bloc, state, isMobile: true),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreSlider(BuildContext context, JobBloc bloc, JobState state, {bool isMobile = false}) {
    final sliderWidget = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceBorder,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      child: Slider(
        value: state.minMatchScore.toDouble(),
        min: 50,
        max: 95,
        divisions: 9,
        onChanged: (val) => bloc.add(MinMatchScoreChanged(val.toInt())),
      ),
    );

    return Row(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const Text(
          'Min Match:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withAlpha(80)),
          ),
          child: Text(
            '${state.minMatchScore}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        if (isMobile)
          Expanded(child: sliderWidget)
        else
          SizedBox(
            width: 130,
            child: sliderWidget,
          ),
      ],
    );
  }
}

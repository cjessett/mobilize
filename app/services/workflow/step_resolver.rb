# Walks a workflow's step tree for one run. Top-level steps execute in
# position order; a router step descends into the branches whose segment
# matches the person (first match only, or every match in order), then pops
# back out to the step after the router. Branch progress is tracked in
# run.context (persisted by the caller).
class Workflow::StepResolver
  def initialize(run)
    @run = run
    @workflow = run.workflow
    @person = run.person
  end

  def first_step
    steps.where(parent_step_id: nil).order(:position).first
  end

  # The step to execute after `after`; nil when the run is finished.
  def next_step(after)
    return enter_router(after) if after.router?

    sibling_after(after)
  end

  private

  def steps = @workflow.workflow_steps

  def enter_router(router)
    matched = matched_branch_indexes(router)
    router_context(router)["matched"] = matched
    enter_branch(router, 0) || sibling_after(router)
  end

  # First step of the i-th *matched* branch, skipping empty branches.
  # nil when there are no more matched branches.
  def enter_branch(router, i)
    branch_index = router_context(router)["matched"][i]
    return nil if branch_index.nil?

    router_context(router)["i"] = i
    first = steps.where(parent_step_id: router.id, branch_index: branch_index).order(:position).first
    first || enter_branch(router, i + 1)
  end

  def sibling_after(step)
    sibling = steps.where(parent_step_id: step.parent_step_id, branch_index: step.branch_index)
      .where("position > ?", step.position).order(:position).first
    return sibling if sibling
    return nil if step.parent_step_id.nil? # end of the workflow

    # End of a branch: in all_matches mode move to the next matched branch,
    # otherwise continue after the router.
    router = steps.find(step.parent_step_id)
    if router.router_mode == "all_matches"
      next_branch = enter_branch(router, router_context(router)["i"].to_i + 1)
      return next_branch if next_branch
    end
    sibling_after(router)
  end

  def router_context(router)
    @run.context["routers"] ||= {}
    @run.context["routers"][router.id.to_s] ||= { "matched" => [], "i" => 0 }
  end

  def matched_branch_indexes(router)
    branches = router.branches
    matched = branches.each_index.select { |i| branch_matches?(branches[i]) }
    matched = matched.take(1) if router.router_mode == "first_match"
    matched
  end

  # A branch without a segment is the default/else branch and always matches.
  def branch_matches?(branch)
    segment_id = branch["segment_id"]
    return true if segment_id.blank?

    segment = @workflow.organization.segments.find_by(id: segment_id)
    segment.present? && segment.people.exists?(@person.id)
  end
end

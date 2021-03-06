# encoding: utf-8

#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

module Pbs::GroupAbility
  extend ActiveSupport::Concern

  MEMBER_COUNT_MANAGERS = [Group::Bund::MitarbeiterGs,
                           Group::Bund::Sekretariat,
                           Group::Kantonalverband::Kantonsleitung,
                           Group::Kantonalverband::Sekretariat,
                           Group::Region::Regionalleitung,
                           Group::Region::Sekretariat]

  included do
    on(Group) do
      permission(:layer_and_below_full).may(:modify_superior).if_mitarbeiter_gs

      permission(:any).may(:evaluate_census).if_member

      permission(:layer_and_below_full).
        may(:show_population, :create_member_counts).
        in_same_layer_or_below

      permission(:layer_and_below_full).
        may(:remind_census, :update_member_counts, :delete_member_counts).
        in_same_layer_or_below_if_leader

      permission(:approve_applications).may(:pending_approvals).if_layer_and_approver_in_group

      permission(:any).may(:'index_event/camps').all
      permission(:group_full).may(:'export_event/camps').in_same_group
      permission(:group_and_below_full).may(:'export_event/camps').in_same_group_or_below
      permission(:layer_read).may(:'export_event/camps').in_same_layer
      permission(:layer_and_below_read).may(:'export_event/camps').in_same_layer_or_below
    end
  end

  def in_same_layer_or_below_if_leader
    in_same_layer_or_below && role_type?(*MEMBER_COUNT_MANAGERS)
  end

  def if_mitarbeiter_gs
    role_type?(Group::Bund::MitarbeiterGs)
  end

  def if_layer_and_approver_in_group
    user_roles = user.roles.collect(&:class)
    approving_group_roles = group.role_types.select do |type|
      type.permissions.include?(:approve_applications)
    end
    if_layer_group && contains_any?(user_roles, approving_group_roles)
  end

end

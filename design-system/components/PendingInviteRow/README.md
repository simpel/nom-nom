**Removed.** An invite row is ListRow's Invite shape — see ListRow.

`NomNom.PendingInviteRow` no longer exists. The replacement:

```js
h(N.Section, { title: 'Invited' },
  h(N.Card, { layout: 'list' },
    h(N.ListRow, { leading: h(N.Avatar, { name: email, size: 'sm' }), title: email, meta: 'Invited 2 days ago', chevron: false,
      trailing: [
        h(N.AppButton, { key: 'r', variant: 'secondary', appearance: 'ghost', size: 'sm', onClick: resend }, 'Resend'),
        h(N.AppButton, { key: 'x', variant: 'destructive', appearance: 'ghost', size: 'sm', iconOnly: true, icon: 'x', label: 'Revoke invite', onClick: revoke })] })))
```

This folder is a leftover: the publishing tool used in chat can add and replace files but not delete them. It can go in a Claude Code session.
